// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import { IMe3Token } from "./interface/IMe3Token.sol";
import { IMe3Storage } from "./interface/IMe3Storage.sol";
import { IMe3StorageSchema } from "./interface/IMe3StorageSchema.sol";
import { SafeMath } from "./libs/SafeMath.sol";
import { Ownable } from "./libs/Ownable.sol";

contract Me3Farm is Ownable, IMe3StorageSchema {
    using SafeMath for uint256;

    IMe3Storage public immutable me3Storage;
    IMe3Token public immutable me3Token;

    uint256 internal REWARD_PERHOUR_REVERSE_RATIO = 100000; //0.001%
    uint256 public totalFarmValue;
    uint256 private REFRESH_RATE = 1 * 60 * 60; // 1 hour
    uint256 private MAX_STAKING_POOL_SIZE_PERCENT = 10;
    uint256 public MAX_STAKING_POOL_SIZE;
    uint256 private PRECISION_VALUE = 100 * (10**9);
    uint256 private YEAR_SECONDS = 365 * 24 * 60 * 60;
    uint256 public LOCK_PERIOD = 30 * 60; // 30 minutes

    uint256 internal RewardPercentPerRefreshRate;

    //// Events Declaration
    event Stake(address indexed depositor, uint256 indexed amount, uint256 indexed recordId);
    event Withdraw(address indexed owner, uint256 indexed amount, uint256 indexed recordId);
    event ApyValue(uint256 indexed apy);
    event RefreshRate(uint256 indexed refreshRate);
    event MaxStakingPoolSize(uint256 indexed maxStakingPoolSize);
    event MaxStakingPoolSizePercent(uint256 indexed maxStakingPoolSizePercent);
    event PrecisionValue(uint256 indexed precisionValue);

    constructor(address storageAddress, address tokenAddress) {
        me3Storage = IMe3Storage(storageAddress);
        me3Token = IMe3Token(tokenAddress);
    }

    function getApyValue() public view returns (uint256) {
        return REWARD_PERHOUR_REVERSE_RATIO;
    }

    function getRefreshRate() public view returns (uint256) {
        return REFRESH_RATE;
    }

    function getMaxStakingPoolSize() public view returns (uint256) {
        return MAX_STAKING_POOL_SIZE;
    }

    function getMaxStakingPoolSizePercent() public view returns (uint256) {
        return MAX_STAKING_POOL_SIZE_PERCENT;
    }

    function getTotalFarmValue() public view returns (uint256) {
        return totalFarmValue;
    }

    function getPrecisionValue() public view returns (uint256) {
        return PRECISION_VALUE;
    }

    function getFixedDepositRecord(uint256 recordId) external view returns (FixedDepositRecord memory) {
        return _getFixedDepositRecordById(recordId);
    }

    function _getFixedDepositRecordById(uint256 recordId) internal view returns (FixedDepositRecord memory) {
        (
            uint256 recordId,
            address payable depositorId,
            uint256 amount,
            uint256 depositDateInSeconds,
            uint256 lockPeriodInSeconds,
            uint256 rewardAmountRecieved,
            bool hasWithdrawn
        ) = me3Storage.getRecordById(recordId);
        FixedDepositRecord memory fixedDepositRecord = FixedDepositRecord(
            recordId,
            depositorId,
            hasWithdrawn,
            amount,
            depositDateInSeconds,
            lockPeriodInSeconds,
            rewardAmountRecieved
        );
        return fixedDepositRecord;
    }

    function updateApyValue(uint256 _apyValue) public onlyOwner {
        REWARD_PERHOUR_REVERSE_RATIO = _apyValue;

        emit ApyValue(REWARD_PERHOUR_REVERSE_RATIO);
    }

    function updateRefreshRate(uint256 _refreshRate) public onlyOwner {
        REFRESH_RATE = _refreshRate;

        emit RefreshRate(REFRESH_RATE);
    }

    function updateMaxStakingPoolSize() public onlyOwner {
        // 10% of the me3Token total supply
        MAX_STAKING_POOL_SIZE = (me3Token.totalSupply() * MAX_STAKING_POOL_SIZE_PERCENT) / 100;

        emit MaxStakingPoolSize(MAX_STAKING_POOL_SIZE);
    }

    function updateMaxStakingPoolSizePercent(uint256 _maxStakingPoolSizePercent) public onlyOwner {
        MAX_STAKING_POOL_SIZE_PERCENT = _maxStakingPoolSizePercent;

        emit MaxStakingPoolSizePercent(MAX_STAKING_POOL_SIZE_PERCENT);
    }

    function updatePrecisionValue(uint256 _precisionValue) public onlyOwner {
        PRECISION_VALUE = _precisionValue;

        emit PrecisionValue(PRECISION_VALUE);
    }

    function stake(uint256 amount, uint256 lockPeriod) public returns (bool) {
        address payable depositor = msg.sender;

        uint256 depositDate = block.timestamp;

        _validateLockPeriod(lockPeriod);

        require(me3Token.balanceOf(depositor) >= amount, "Not enough me3 token balance");

        //check that the totalFarmValue is less than the max staking pool size
        require(totalFarmValue < MAX_STAKING_POOL_SIZE, "The totalFarmValue has reached limit");
        // check that the amount is less than the maximum staking pool size
        require(amount < MAX_STAKING_POOL_SIZE, "Amount is greater than the maximum staking pool size");
        // check that the totalFarmValue + amount is less than the maximum staking pool size
        require(totalFarmValue + amount <= MAX_STAKING_POOL_SIZE, "The totalFarmValue + amount has reached limit");

        // check allowance for the depositor
        require(me3Token.allowance(depositor, address(this)) >= amount, "Not enough me3 token allowance");

        // transfer me3 token to the smart contract
        me3Token.transferFrom(depositor, address(this), amount);

        // update the totalFarmValue
        totalFarmValue = totalFarmValue.add(amount);

        uint256 recordId = me3Storage.createDepositRecordMapping(amount, lockPeriod, depositDate, depositor, 0, false);

        me3Storage.createDepositorToDepositRecordIndexToRecordIDMapping(depositor, recordId);

        me3Storage.createDepositorAddressToDepositRecordMapping(depositor, recordId, amount, lockPeriod, depositDate, 0, false);

        emit Stake(depositor, amount, recordId);

        return true;
    }

    function withdraw(uint256 recordId) public returns (bool) {
        address payable recepient = msg.sender;

        FixedDepositRecord memory fixedDepositRecord = _getFixedDepositRecordById(recordId);

        uint256 derivativeAmount = fixedDepositRecord.amountDeposited;

        require(derivativeAmount > 0, "Cannot withdraw 0 shares");

        require(fixedDepositRecord.depositorId == recepient, "Withdraw can only be called by depositor");

        uint256 lockPeriod = fixedDepositRecord.lockPeriodInSeconds;
        uint256 depositDate = fixedDepositRecord.depositDateInSeconds;

        _validateLockTimeHasElapsedAndHasNotWithdrawn(recordId);

        // pending when i write the calculateReward function
        uint256 rewardAmount = calculateReward(recordId);
        uint256 withdrawAmount = derivativeAmount + rewardAmount;

        me3Storage.updateDepositRecordMapping(recordId, derivativeAmount, lockPeriod, depositDate, recepient, rewardAmount, true);

        // execute transfer after storage manipulation
        me3Token.transfer(recepient, withdrawAmount);

        emit Withdraw(recepient, withdrawAmount, recordId);
    }

    function _validateLockPeriod(uint256 lockPeriod) internal view returns (bool) {
        require(lockPeriod > 0, "Lock period must be greater than 0");
        require(lockPeriod <= LOCK_PERIOD, "Lock period must be less than or equal to 30 minutes");
        return true;
    }

    function _validateLockTimeHasElapsedAndHasNotWithdrawn(uint256 recordId) internal view returns (bool) {
        FixedDepositRecord memory depositRecord = _getFixedDepositRecordById(recordId);

        // calculate maturityDate (funds will be locked until maturityDate)
        uint256 maturityDate = depositRecord.depositDateInSeconds + depositRecord.lockPeriodInSeconds;

        bool hasWithdrawn = depositRecord.hasWithdrawn;

        require(!hasWithdrawn, "Individual has already withdrawn");

        uint256 currentTimeStamp = block.timestamp;

        require(currentTimeStamp >= maturityDate, "Funds are still locked, wait until lock period expires");

        return true;
    }

    function _updateRecord(FixedDepositRecord memory record) internal returns (bool) {
        me3Storage.updateDepositRecordMapping(
            record.recordId,
            record.amountDeposited,
            record.lockPeriodInSeconds,
            record.depositDateInSeconds,
            record.depositorId,
            record.rewardAmountRecieved,
            record.hasWithdrawn
        );
    }

    function calculateReward(uint256 recordId) public view returns (uint256) {
        FixedDepositRecord memory record = _getFixedDepositRecordById(recordId);

        uint256 depositDate = record.depositDateInSeconds;

        uint256 depositAmount = record.amountDeposited;

        uint256 duration = block.timestamp.sub(depositDate);

        uint256 numberOfHours = calculateHoursPassed(duration);

        uint256 rewardAmount = (numberOfHours.mul(depositAmount)).div(REWARD_PERHOUR_REVERSE_RATIO);

        return rewardAmount;
    }

    function calculateHoursPassed(uint256 duration) public view returns (uint256) {
        uint256 numberOfHours = duration / 1 hours;

        return numberOfHours;
    }
}
