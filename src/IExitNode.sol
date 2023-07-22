// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExitNode {
    /**
     * Redeem funds.
     */

    function redeem(bytes memory response, uint256 redeemGasFee, address outputAddress) external payable;

    /**
     * Delay gas payment to the relayment.
     */

    function withdraw(uint256 withdrawGasFee, bytes memory response) external;

    /**
     * broadcast redeem information to other chains
     */

    function registerRedeem(uint256 vaultId, uint32 _otherChainId, uint256 gasFee) external;
}
