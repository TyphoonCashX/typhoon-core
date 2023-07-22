// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


interface IExitNode {

    /**
    Redeem funds from bridge.
     */

    function redeem(bytes memory response) external returns (bool);

    /**
    Delay gas payment to the relayment.
     */

    function withdraw(uint256 gasFee, uint256 vaultId) external returns (bool);
    
}