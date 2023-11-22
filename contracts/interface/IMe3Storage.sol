// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;
import { IMe3StorageSchema } from "./IMe3StorageSchema.sol";

interface IMe3Storage is IMe3StorageSchema {
    function getRecordIndexFromDepositor(address member) external view returns (uint256);

    function createDepositRecordMapping(
        uint256 amount,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        address payable depositor,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external returns (uint256);

    function updateDepositRecordMapping(
        uint256 depositRecordId,
        uint256 amount,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        address payable depositor,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external;

    function getRecordId() external view returns (uint256);

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
        );

    function getRecords() external view returns (FixedDepositRecord[] memory);

    function createDepositorAddressToDepositRecordMapping(
        address payable depositor,
        uint256 recordId,
        uint256 amountDeposited,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external;

    function createDepositorToDepositRecordIndexToRecordIDMapping(address payable depositor, uint256 recordId) external;
}
