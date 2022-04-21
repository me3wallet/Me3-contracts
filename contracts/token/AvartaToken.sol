// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./AvartaTokenMinters.sol";

contract AvartaToken is Initializable, ContextUpgradeable, ERC20Upgradeable, AvartaTokenMinters {
  using SafeMath for uint256;

  event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);

  event AddedBlackList(address _user);

  event RemovedBlackList(address _user);

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  /// @notice A record of each accounts delegate
  mapping(address => address) public delegates;

  /// @notice A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice The EIP-712 typehash for EIP-2612 permit
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  /// @notice A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;

  mapping(address => bool) public isBlackListed;

  function initialize(
    string memory name_,
    string memory symbol_,
    uint256 totalSupply_,
    address owner_
  ) public initializer {
    __Ownable_init();
    __ERC20_init(name_, symbol_);
    __Context_init();

    grantAccess(msg.sender);
    mint(owner_, totalSupply_);
    _transferOwnership(owner_);
  }

  /**
   * @notice Burn `rawAmount` tokens from `account`
   * @param account The address of the account to burn
   * @param rawAmount The number of tokens to burn
   */
  function burnFrom(address account, uint256 rawAmount) public {
    address spender = msg.sender;
    require(account != address(0) && spender != account, "AvartaToken::burnFrom: cannot burn from the zero address");

    uint256 spenderAllowance = allowance(account, spender);
    require(spenderAllowance >= rawAmount, "AvartaToken::burnFrom: burn amount exceeds allowance");
    unchecked {
      _approve(account, spender, spenderAllowance - rawAmount);
    }
    _burn(account, rawAmount);
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
    require(signatory != address(0), "AvartaToken::delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "AvartaToken::delegateBySig: invalid nonce");
    require(block.timestamp <= expiry, "AvartaToken::delegateBySig: signature expired");
    _delegate(signatory, delegatee);
  }

  /* @notice domainSeparator */
  // solhint-disable func-name-mixedcase
  function DOMAIN_SEPARATOR() public view returns (bytes32) {
    return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
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
    require(owner != address(0), "AvartaToken::permit: invalid signature");
    require(block.timestamp <= deadline, "AvartaToken::permit: signature expired");

    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
    require(owner == ecrecover(digest, v, r, s), "AvartaToken::permit: invalid signature");
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
    require(blockNumber < block.number, "AvartaToken::getPriorVotes: not yet determined");

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
      uint32 center = upper - (upper - lower) / 2;
      // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      }
      if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
    _mint(_to, _amount);
    return true;
  }

  function addBlackList(address _evilUser) public onlyOwner {
    isBlackListed[_evilUser] = true;
    emit AddedBlackList(_evilUser);
  }

  function removeBlackList(address _clearedUser) public onlyOwner {
    isBlackListed[_clearedUser] = false;
    emit RemovedBlackList(_clearedUser);
  }

  function destroyBlackFunds(address _blackListedUser) public onlyOwner {
    require(isBlackListed[_blackListedUser]);
    uint256 dirtyFunds = balanceOf(_blackListedUser);
    if (dirtyFunds > 0) {
      _burn(_blackListedUser, dirtyFunds);
      emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
  }

  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    // solhint-disable no-inline-assembly
    assembly {
      chainId := chainid()
    }
    return chainId;
  }

  function getBlackListStatus(address _maker) external view returns (bool) {
    return isBlackListed[_maker];
  }

  function _msgSender() internal view override returns (address) {
    return ContextUpgradeable._msgSender();
  }

  function _msgData() internal view override returns (bytes calldata) {
    return ContextUpgradeable._msgData();
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator);
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _afterTokenTransfer(currentDelegate, delegatee, delegatorBalance);
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint256 oldVotes,
    uint256 newVotes
  ) internal {
    uint32 blockNumber = safe32(block.number, "AvartaToken::_writeCheckpoint: block number exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function _afterTokenTransfer(
    address srcRep,
    address dstRep,
    uint256 amount
  ) internal override {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;

        (bool success, uint256 srcRepNew) = srcRepOld.trySub(amount);
        require(success, "AvartaToken::_moveVotes: vote amount underflows");

        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;

        (bool success, uint256 dstRepNew) = dstRepOld.tryAdd(amount);
        require(success, "AvartaToken::_afterTokenTransfer: vote amount overflows");

        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }
}
