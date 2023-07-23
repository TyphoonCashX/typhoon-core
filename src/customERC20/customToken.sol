
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/ERC20.sol";

contract CustomToken is ERC20 {

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){}

    function mint(address reciver, uint256 amount) public {
        _mint(reciver, amount);
    }
}