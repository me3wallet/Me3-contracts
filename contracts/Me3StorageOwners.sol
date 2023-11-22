// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

/**
 * @dev Contract for Me3s proxy layer
 */

contract Me3StorageOwners {
    address owner;
    mapping(address => bool) private storageOracles;

    //// Events Declaration
    event StorageOracleStatus(address indexed oracle, bool indexed status);

    constructor() public {
        owner = msg.sender;
    }

    function changeStorageOracleStatus(address oracle, bool status) external onlyOwner {
        storageOracles[oracle] = status;

        emit StorageOracleStatus(oracle, status);
    }

    function activateStorageOracle(address oracle) external onlyOwner {
        storageOracles[oracle] = true;

        emit StorageOracleStatus(oracle, true);
    }

    function deactivateStorageOracle(address oracle) external onlyOwner {
        storageOracles[oracle] = false;

        emit StorageOracleStatus(oracle, false);
    }

    function reAssignStorageOracle(address newOracle) external onlyStorageOracle {
        storageOracles[msg.sender] = false;
        storageOracles[newOracle] = true;
    }

    function transferStorageOwnership(address payable newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }

        // require(newOwner == address(0), "new owneru");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized access to contract");
        _;
    }

    modifier onlyStorageOracle() {
        bool hasAccess = storageOracles[msg.sender];
        require(hasAccess, "unauthorized access to contract");
        _;
    }
}
