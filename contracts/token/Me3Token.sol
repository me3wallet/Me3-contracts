// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';

contract Me3Token is IERC20 {

    /// @notice An event that's emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event that's emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /// @notice A record of each account's delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking the number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for EIP-2612 permit
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowance;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
    * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
    * a default value of 18.
    *
    * To select a different value for {decimals}, use {_setupDecimals}.
    *
    * All of these values are immutable: they can only be set once during
    * construction.
    */
    constructor(
        string memory name_,
        string memory symbol_

    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;


        // Mint tokens to contract deployer with a hard cap of 1,000,000,000
        uint256 initialSupply = 1000000000 * (10**_decimals);
        _mint(msg.sender, initialSupply);
    }

    /**
    * @dev Returns the name of the token.
    */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the number of decimals used to get its user representation.
    * For example, if `decimals` equals `2`, a balance of `505` tokens should
    * be displayed to a user as `5,05` (`505 / 10 ** 2`).
    *
    * Tokens usually opt for a value of 18, imitating the relationship between
    * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
    * called.
    *
    * NOTE: This information is only used for _display_ purposes: it in
    * no way affects any of the arithmetic of the contract, including
    * {IERC20-balanceOf} and {IERC20-transfer}.
    */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
    * @dev See {IERC20-totalSupply}.
    */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function maxSupply() public view virtual returns (uint256) {
        return 1000000000 * (10**_decimals);
    }

    /**
    * @dev See {IERC20-balanceOf}.
    */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /* @notice domainSeparator */
    // solhint-disable func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(_name)), getChainId(), address(this)));
    }

    /**
    * @dev See {IERC20-allowance}.
    */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
    * @notice Approve `spender` to transfer up to `amount` from `src`
    * @dev This will overwrite the approval amount for `spender`
    *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
    * @param spender The address of the account which may transfer tokens
    * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
    * @return Whether or not the approval succeeded
    */
    function approve(address spender, uint256 rawAmount) external override returns (bool) {
        _approve(msg.sender, spender, rawAmount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 rawAmount
    ) internal {
        uint256 amount;
        if (rawAmount == type(uint256).max) {
            amount = type(uint256).max;
        } else {
            amount = safe96(rawAmount, "Me3Token::approve: amount exceeds 96 bits");
        }

        _allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
    * @notice Transfer `amount` tokens from `msg.sender` to `dst`
    * @param dst The address of the destination account
    * @param rawAmount The number of tokens to transfer
    * @return Whether or not the transfer succeeded
    */
    function transfer(address dst, uint256 rawAmount) external override returns (bool) {
        uint256 amount = safe96(rawAmount, "Me3Token::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
    * @notice Transfer `amount` tokens from `src` to `dst`
    * @param src The address of the source account
    * @param dst The address of the destination account
    * @param rawAmount The number of tokens to transfer
    * @return Whether or not the transfer succeeded
    */
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external override returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = _allowance[src][spender];
        uint256 amount = safe96(rawAmount, "Me3Token::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = sub96(spenderAllowance, amount, "Me3Token::transferFrom: transfer amount exceeds spender allowance");
            _allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
    * @notice Delegates votes from signatory to `delegatee`
    * @param delegatee The address to delegate votes to
    * @param nonce The contract state required to match the signature
    * @param expiry The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Me3Token::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Me3Token::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "Me3Token::delegateBySig: signature expired");
        _delegate(signatory, delegatee);
    }

    /**
    * @notice Approves spender to spend on behalf of owner.
    * @param owner The signer of the permit
    * @param spender The address to approve
    * @param deadline The time at which the signature expires
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        require(owner == ecrecover(digest, v, r, s), "Me3Token::permit: invalid signature");
        require(owner != address(0), "Me3Token::permit: invalid signature");
        require(block.timestamp <= deadline, "Me3Token::permit: signature expired");
        _approve(owner, spender, value);
    }

    /**
    * @notice Gets the current votes balance for `account`
    * @param account The address to get votes balance
    * @return The number of current votes for `account`
    */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
    * @notice Determine the prior number of votes for an account as of a block number
    * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    * @param account The address of the account to check
    * @param blockNumber The block number to get the vote balance at
    * @return The number of votes the account had as of the given block
    */
    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "Me3Token::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = _balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        require(src != address(0), "Me3Token::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Me3Token::_transferTokens: cannot transfer to the zero address");

        _balances[src] = sub96(_balances[src], amount, "Me3Token::_transferTokens: transfer amount exceeds balance");
        _balances[dst] = add96(_balances[dst], amount, "Me3Token::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = sub96(srcRepOld, amount, "Me3Token::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = add96(dstRepOld, amount, "Me3Token::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, "Me3Token::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint256) {
        require(n < 2**96, errorMessage);
        return uint256(n);
    }

    function add96(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        // solhint-disable no-inline-assembly
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
    function _mint(address account, uint256 amount) internal virtual {
        require(totalSupply() + amount <= 1000000000 * (10**_decimals), "Exceeds max supply");
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] = _balances[account] + amount;

        _moveDelegates(delegates[address(0)], delegates[account], amount);

        emit Transfer(address(0), account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // Function removed: mint(address _to, uint256 _amount)

    // Removed the mint function

    // Removed the onlyMinter modifier
}
