// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExitNode {
    /**
     *  @notice Function called to enter the pending registry, awaiting withdrawal
     *  @param response : generated proof deposited for verification
     *  @param redeemGasFee : gas fee for redeeming, delegated to the relayer
     *  @param outputAddress : output address for the bridge, where the tokens will be deposited
     */

    function redeem(bytes memory response, uint256 redeemGasFee, address outputAddress) external payable;

    /**
     * @notice withdraw funds from the bridge
     * @param withdrawGasFee : withdrawal gas fees delegated to the relayer.
     * @param response : proof generated by sismo
     */

    function withdraw(uint256 withdrawGasFee, bytes memory response) external;

    /**
     * @notice broadcast to other chains that claim has already been made
     * @param vaultId : vaultId to the user.
     */
    function registerRedeem(uint256 vaultId, uint32 _otherChainId, uint256 gasFee) external;
}
