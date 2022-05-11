// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract AvartaTokenMinters is OwnableUpgradeable {
  mapping(address => bool) public minters;

  //// Events Declaration
  event AccessGranted(address indexed owner, address indexed minter);
  event AccessRevoked(address indexed owner, address indexed minter);

  modifier onlyMinter() {
    bool hasAccess = minters[msg.sender];
    require(hasAccess == true, "mint access has not been granted to this account");
    _;
  }

  function __AvartaTokenMinters_init() internal onlyInitializing {
    __AvartaTokenMinters_init_unchained();
  }

  function __AvartaTokenMinters_init_unchained() internal onlyInitializing {
    __Ownable_init_unchained();
  }

  function grantAccess(address minter) public onlyOwner {
    bool hasAccess = minters[minter];

    require(hasAccess == false, "minter has already been granted access");
    minters[minter] = true;

    emit AccessGranted(msg.sender, minter);
  }

  function revokeAccess(address minter) public onlyOwner {
    bool hasAccess = minters[minter];

    require(hasAccess == true, "minter has not been granted access");
    minters[minter] = false;

    emit AccessRevoked(msg.sender, minter);
  }

  uint256[49] private __gap;
}
