// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;
import { SafeMath } from "./libs/SafeMath.sol";
import { AvartaStorageOwners } from "./AvartaStorageOwners.sol";
import { IAvartaStorageSchema } from "./interface/IAvartaStorageSchema.sol";

/**
 * @dev Contract for Avarta's proxy layer
 */

contract AvartaStorage is IAvartaStorageSchema, AvartaStorageOwners {
    using SafeMath for uint256;
    uint256 public DepositRecordId;

    FixedDepositRecord[] public fixedDepositRecords;

    mapping(uint256 => FixedDepositRecord) public DepositRecordMapping;

    //depositor address to depositor cycle mapping
    mapping(address => mapping(uint256 => FixedDepositRecord)) public DepositRecordToDepositorMapping;

    //  This maps the depositor to the record index and then to the record ID
    mapping(address => mapping(uint256 => uint256)) DepositorToRecordIndexToRecordIDMapping;

    //  This tracks the number of records by index created by a depositor
    mapping(address => uint256) public DepositorToDepositorRecordIndexMapping;

    function getRecordIndexFromDepositor(address member) external view returns (uint256) {
        return DepositorToDepositorRecordIndexMapping[member];
    }

    function createDepositRecordMapping(
        uint256 amount,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        address payable depositor,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external onlyStorageOracle returns (uint256) {
        DepositRecordId += 1;

        FixedDepositRecord storage _fixedDeposit = DepositRecordMapping[DepositRecordId];

        _fixedDeposit.recordId = DepositRecordId;
        _fixedDeposit.amountDeposited = amount;
        _fixedDeposit.lockPeriodInSeconds = lockPeriodInSeconds;
        _fixedDeposit.depositDateInSeconds = depositDateInSeconds;
        _fixedDeposit.hasWithdrawn = hasWithdrawn;
        _fixedDeposit.depositorId = depositor;
        _fixedDeposit.rewardAmountRecieved = rewardAmountRecieved;

        fixedDepositRecords.push(_fixedDeposit);

        return _fixedDeposit.recordId;
    }

    function updateDepositRecordMapping(
        uint256 depositRecordId,
        uint256 amount,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        address payable depositor,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external onlyStorageOracle {
        FixedDepositRecord storage _fixedDeposit = DepositRecordMapping[depositRecordId];

        _fixedDeposit.recordId = depositRecordId;
        _fixedDeposit.amountDeposited = amount;
        _fixedDeposit.lockPeriodInSeconds = lockPeriodInSeconds;
        _fixedDeposit.depositDateInSeconds = depositDateInSeconds;
        _fixedDeposit.hasWithdrawn = hasWithdrawn;
        _fixedDeposit.depositorId = depositor;
        _fixedDeposit.rewardAmountRecieved = rewardAmountRecieved;

        //fixedDepositRecords.push(_fixedDeposit);
    }

    function getRecordId() external view returns (uint256) {
        return DepositRecordId;
    }

    function getRecordById(uint256 depositRecordId)
        external
        view
        returns (
            uint256 recordId,
            address payable depositorId,
            uint256 amount,
            uint256 depositDateInSeconds,
            uint256 lockPeriodInSeconds,
            uint256 rewardAmountRecieved,
            bool hasWithdrawn
        )
    {
        FixedDepositRecord memory records = DepositRecordMapping[depositRecordId];

        return (
            records.recordId,
            records.depositorId,
            records.amountDeposited,
            records.depositDateInSeconds,
            records.lockPeriodInSeconds,
            records.rewardAmountRecieved,
            records.hasWithdrawn
        );
    }

    function getRecords() external view returns (FixedDepositRecord[] memory) {
        return fixedDepositRecords;
    }

    function createDepositorAddressToDepositRecordMapping(
        address payable depositor,
        uint256 recordId,
        uint256 amountDeposited,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external onlyStorageOracle {
        mapping(uint256 => FixedDepositRecord) storage depositorAddressMapping = DepositRecordToDepositorMapping[depositor];
        depositorAddressMapping[recordId].recordId = recordId;
        depositorAddressMapping[recordId].depositorId = depositor;
        depositorAddressMapping[recordId].amountDeposited = amountDeposited;
        depositorAddressMapping[recordId].depositDateInSeconds = depositDateInSeconds;
        depositorAddressMapping[recordId].lockPeriodInSeconds = lockPeriodInSeconds;
        depositorAddressMapping[recordId].rewardAmountRecieved = rewardAmountRecieved;
        depositorAddressMapping[recordId].hasWithdrawn = hasWithdrawn;
    }

    function createDepositorToDepositRecordIndexToRecordIDMapping(address payable depositor, uint256 recordId) external onlyStorageOracle {
        DepositorToDepositorRecordIndexMapping[depositor] = DepositorToDepositorRecordIndexMapping[depositor].add(1);

        uint256 DepositorCreatedRecordIndex = DepositorToDepositorRecordIndexMapping[depositor];
        mapping(uint256 => uint256) storage depositorCreatedRecordIndexToRecordId = DepositorToRecordIndexToRecordIDMapping[depositor];
        depositorCreatedRecordIndexToRecordId[DepositorCreatedRecordIndex] = recordId;
    }
}
