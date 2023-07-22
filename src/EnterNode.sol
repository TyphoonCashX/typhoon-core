git push
icense-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IEnterNode.sol";

contract EnterNode is IEnterNode {

    // constants and state variables

    uint256 public constant DEPOSIT_AMOUNT = 10 * 10**18;
    mapping(uint256 => address) public registry;

    // events 

    event FireDeposit(address indexed sender);

    // errors

    error IncorrectDepositAmount();
    

    function deposit() external payable returns (bool) {
        
        require()
    }


}
