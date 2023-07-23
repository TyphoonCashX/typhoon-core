// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IEnterNode {
    /**
     * @notice deposit funds in the birdge, on the chain of origin.
     */

    function deposit() external payable;
}
