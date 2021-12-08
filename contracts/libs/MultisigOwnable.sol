// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are multiple accounts (owners) that can be granted exclusive access to
 * specific functions.
 *
 * The owner account is by default the only one - contract deployer.
 * This can later be changed with {updateOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract MultisigOwnable is Context {
    address[] public owners;
    mapping(address => bool) public isOwner;
    mapping(uint => MultisigOwnableTransaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    uint public transactionCount;

    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);

    struct MultisigOwnableTransaction {
        address addr;
        uint value;
        bool public executed;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        owners.push(msgSender);
        isOwner[msgSender] = true;
        
        emit OwnerAddition(msgSender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner[_msgSender()], "Ownable: caller is not the owner");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }
    modifier transactionExists(uint transactionId) {
        require(transactionId < transactionCount);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }
    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }
    modifier notExecuted(uint transactionId) {
        require(![transactionId].executed);
        _;
    }

    /**
     * @dev Allows to add a new owner. 
     * @param owner Address of new owner.
     */
    function addOwner(address owner) public onlyOwner {
        isOwner[owner] = true;
        owners.push(owner);

        emit OwnerAddition(owner);
    }

    /**
     * @dev Allows to remove an owner. 
     * @param owner Address of owner.
     */
    function removeOwner(address owner) public onlyOwner {
        isOwner[owner] = false;
        for (uint i = 0; i < owners.length - 1; i ++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;

        emit OwnerRemoval(owner);
    }

    /**
     * @dev Allows to replace an owner with a new owner.
     * @param owner Address of owner to be replaced.
     * @param newOwner Address of new owner.
     */
    function replaceOwner(address owner, address newOwner) public onlyOwner {
        for (uint i = 0; i < owners.length; i ++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;

        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    function confirmTransaction(uint transactionId) public 
        ownerExists(msg.sender) 
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
    }

    function executeTransaction(uint transactionId) public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        _executeTransaction(transactionId);
    }

    function _executeTransaction(uint transactionId) internal virtual returns (bool);

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address addr, uint value) internal returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = MultisigOwnableTransaction({
            addr: addr,
            value: value,
            executed: false
        });
        transactionCount += 1;
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value) public returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value);
        confirmTransaction(transactionId);
    }
}
