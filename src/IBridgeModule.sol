// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBridgeModule {

    /**
    @notice broadact the pending registry to all the chains
    @param newVaultId : new vaultId in the pending registry 
     */
    function broadcastRegister(uint256 newVaultId) external payable;

    /**
    @notice getter for the chain id
     */

    function thisChainId() external view returns (uint32);
}
