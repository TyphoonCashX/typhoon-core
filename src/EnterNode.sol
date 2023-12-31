// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IEnterNode.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

contract EnterNode is IEnterNode {
    // constants and state variables

    uint256 public constant DEPOSIT_AMOUNT = 10 * 10 ** 18;
    address TOKEN_ADDRESS;
    address[] public registry;

    // events

    event FireDeposit(address indexed sender);

    constructor(address tokenAddress){
        TOKEN_ADDRESS = tokenAddress;
    }

    /**
     * @dev interface
     */

    function deposit() external payable {
        IERC20(TOKEN_ADDRESS).transferFrom(msg.sender, address(this), DEPOSIT_AMOUNT);
        registry.push(msg.sender);
        emit FireDeposit(msg.sender);
    }
}
