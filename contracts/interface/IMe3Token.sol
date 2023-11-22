// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import { IERC20 } from "./IERC20.sol";

interface IMe3Token is IERC20 {
    function getBlackListStatus(address _maker) external view returns (bool);

    function addBlackList(address _evilUser) external;

    function removeBlackList(address _clearedUser) external;

    function destroyBlackFunds(address _blackListedUser) external;

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external returns (bool);
}
