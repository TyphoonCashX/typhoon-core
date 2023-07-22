// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExitNode {
    /**
     * Redeem funds.
     */

    function redeem(bytes memory response, uint256 redeemGasFee, address outputAddress) external;

    /**
     * Delay gas payment to the relayment.
     */

    function withdraw(uint256 withdrawGasFee, uint256 vaultId) external;
    
    function registerRedeem(uint256 vaultId, uint32 _otherChainId, uint256 gasFee) external;
}
