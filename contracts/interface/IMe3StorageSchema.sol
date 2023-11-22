// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

interface IMe3StorageSchema {
    struct FixedDepositRecord {
        uint256 recordId;
        address payable depositorId;
        bool hasWithdrawn;
        uint256 amountDeposited;
        uint256 depositDateInSeconds;
        uint256 lockPeriodInSeconds;
        uint256 rewardAmountRecieved;
    }
}
