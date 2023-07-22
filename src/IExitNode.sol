// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


interface IExitNode {

    /**
     */

    function redeem(
        bytes memory response,
        uint256 redeemGasFee,
        address outputAddress)
         external returns (bool);

    /**
    Delay gas payment to the relayment.
     */

    function withdraw(
        uint256 withdrawGasFee,
         uint256 vaultId)
          external returns (bool);
    
}