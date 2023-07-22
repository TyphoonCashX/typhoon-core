// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IExitNode.sol";
import "sismo-connect-solidity/SismoConnectLib.sol";
import "sismo-connect-solidity/utils/SismoConnectHelper.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

contract ExitNode is IExitNode, SismoConnect {
    using SismoConnectHelper for SismoConnectVerifiedResult;

    bytes16 private _appId = 0;
    bool private _isImpersonationMode = true;
    uint256 public constant N_BLOCKS_DELAY = 1;
    address public constant ZERO_ADDRESS = address(0x0);
    uint256 public constant DEPOSIT_AMOUNT = 10 * 10 ** 18;

    address public tokenAddress;
    // maps vaultId => boolean, and tracks if claimed was already made or not
    mapping(uint256 => bool) public isClaimed;

    struct PendingRedeem {
        uint256 vaultId;
        address outputAddress;
        uint256 releaseTimestamp;
        uint256 gasFee;
    }

    bytes32 public constant nullRedeemInformation = keccak256(
        abi.encode(PendingRedeem({vaultId: 0x0, outputAddress: address(0x0), releaseTimestamp: 0, gasFee: 0}))
    );

    // errors
    error isAlreadyClaimed(uint256 vaultId);
    error notInPendingList(uint256 vaultId);
    error zeroVaultId();
    error zeroAddress();

    mapping(uint256 => PendingRedeem) public vaultIdToRedeemInformation;

    // constructor

    constructor(address _tokenAddress)
     SismoConnect(buildConfig(_appId, _isImpersonationMode)) {
        tokenAddress = _tokenAddress;
     }

    function redeem(bytes memory response, uint256 redeemGasFee, address outputAddress) external {
        if (outputAddress == ZERO_ADDRESS) {
            revert zeroAddress();
        }

        SismoConnectVerifiedResult memory result = verify({
            responseBytes: response,
            auth: buildAuth({authType: AuthType.VAULT}),
            signature: buildSignature({message: abi.encode(msg.sender)})
        });

        uint256 vaultId = result.getUserId(AuthType.VAULT);

        if (vaultId == 0x0) {
            revert zeroVaultId();
        }

        // This is the moment where we might take you money.

        if (isClaimed[vaultId]) {
            revert isAlreadyClaimed(vaultId);
        }

        isClaimed[vaultId] = true;

        vaultIdToRedeemInformation[vaultId] = PendingRedeem({
            vaultId: vaultId,
            outputAddress: outputAddress,
            releaseTimestamp: block.timestamp + N_BLOCKS_DELAY,
            gasFee: redeemGasFee
        });
    }

    function withdraw(uint256 withdrawGasFee, uint256 vaultId) external {
        // verify if the vault Id is in the pending registry

        PendingRedeem storage pendingRedeem = vaultIdToRedeemInformation[vaultId];
        uint256 gas = pendingRedeem.gasFee + withdrawGasFee;
        IERC20 bridgedToken = IERC20(tokenAddress);

        if (keccak256(abi.encode(pendingRedeem)) == nullRedeemInformation) {

            revert notInPendingList(vaultId);

        }

        bridgedToken.transferFrom(msg.sender, address(this), gas);

        // remove from pending redeems

        delete vaultIdToRedeemInformation[vaultId];

        bridgedToken.transfer(pendingRedeem.outputAddress, DEPOSIT_AMOUNT - gas);
    }
}