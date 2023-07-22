// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBridgeModule {
    function broadcastRegister(uint256 newVaultId) external;

    function thisChainId() view external returns(uint32);
}