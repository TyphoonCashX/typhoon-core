// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IExitNode.sol";
import "sismo-connect-solidity/SismoConnectLib.sol";
import "sismo-connect-solidity/utils/SismoConnectHelper.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "./HyperBridgeModule.sol";
import "./IBridgeModule.sol";

contract ExitNode is IExitNode, SismoConnect, Ownable {

    using SismoConnectHelper for SismoConnectVerifiedResult;

    bool private _isImpersonationMode = true;

    // constants
    uint8 public constant N_BLOCKS_DELAY = 1;
    address public constant ZERO_ADDRESS = address(0x0);
    uint256 public constant DEPOSIT_AMOUNT = 10 * 10 ** 18;

    // final
    address public bridgeModuleAddress;

    // token address
    address public tokenAddress;
    address public bridgeAddress;
    // maps vaultId => boolean, and tracks if claimed was already made or not
    mapping(uint256 => bool) public isRedeemed;

    // pending redeem information
    struct PendingRedeem {
        uint256 vaultId;
        address outputAddress;
        uint256 releaseTimestamp;
        uint256 gasFee;
    }

    // empty struct encoding
    bytes32 public constant nullRedeemInformation = keccak256(
        abi.encode(PendingRedeem({vaultId: 0x0, outputAddress: address(0x0), releaseTimestamp: 0, gasFee: 0}))
    );

    // errors
    error isAlreadyClaimed(uint256 vaultId);
    error isBeingClaimedOnOtherChains(uint256 vaultId);
    error notInPendingList(uint256 vaultId);
    error zeroVaultId();
    error zeroAddress();
    error isNotHyperplaneCaller(address callee);
    error GasFeeHigherThanWithdraw();

    // mapping that associates vaultId to pending redeem information
    mapping(uint256 => PendingRedeem) public vaultIdToRedeemInformation;

    // constructor

    constructor(address _tokenAddress, bytes16 _appId, uint32 _chainId, address _mailbox, address _paymaster)
        SismoConnect(buildConfig(_appId, _isImpersonationMode))
        Ownable()
    {
        tokenAddress = _tokenAddress;
        _deployHyperBridgeModule(_chainId, _mailbox, _paymaster);
    }

    function _deployHyperBridgeModule(uint32 _chainId, address _mailbox, address _paymaster) private onlyOwner {
        bridgeModuleAddress = address(new HyperBridgeModule(_chainId, _mailbox, _paymaster, msg.sender));
    }

    /**
     * @dev interface
     */

    function redeem(bytes memory response, uint256 redeemGasFee, address outputAddress) external payable {
        // make sur that gas fees are not higher than the maximal deposit amount.
        if (redeemGasFee > DEPOSIT_AMOUNT) {
            revert GasFeeHigherThanWithdraw();
        }

        if (outputAddress == ZERO_ADDRESS) {
            revert zeroAddress();
        }

        SismoConnectVerifiedResult memory result = verify({
            responseBytes: response,
            auth: buildAuth({authType: AuthType.VAULT}),
            signature: buildSignature({message: abi.encodePacked(redeemGasFee, outputAddress)})
        });

        uint256 vaultId = result.getUserId(AuthType.VAULT);

        if (vaultId == 0x0) {
            revert zeroVaultId();
        }

        if (isRedeemed[vaultId]) {
            revert isAlreadyClaimed(vaultId);
        }

        isRedeemed[vaultId] = true;

        PendingRedeem memory pendingRedeem = PendingRedeem({
            vaultId: vaultId,
            outputAddress: outputAddress,
            releaseTimestamp: block.timestamp + N_BLOCKS_DELAY,
            gasFee: redeemGasFee
        });

        vaultIdToRedeemInformation[vaultId] = pendingRedeem;

        // use the bridge module interface and broadcast the registered vaultId

        IBridgeModule bridgeModule = IBridgeModule(bridgeModuleAddress);
        //sending the value to the broadcast contract to pay the bridge
        bridgeModule.broadcastRegister{value : msg.value}(vaultId);
        //paying the relayer
        IERC20(tokenAddress).transfer(msg.sender, redeemGasFee);
    }

    /**
     * @dev interface
     */

    function withdraw(uint256 withdrawGasFee, bytes memory response) external {
        // have a signature for the gas fee.

        SismoConnectVerifiedResult memory result = verify({
            responseBytes: response,
            auth: buildAuth({authType: AuthType.VAULT}),
            signature: buildSignature({message: abi.encodePacked(withdrawGasFee)})
        });

        uint256 vaultId = result.getUserId(AuthType.VAULT);

        if (withdrawGasFee > DEPOSIT_AMOUNT) {
            revert GasFeeHigherThanWithdraw();
        }

        PendingRedeem storage pendingRedeem = vaultIdToRedeemInformation[vaultId];
        uint256 gas = pendingRedeem.gasFee + withdrawGasFee;
        IERC20 bridgedToken = IERC20(tokenAddress);

        if (keccak256(abi.encode(pendingRedeem)) == nullRedeemInformation) {
            revert notInPendingList(vaultId);
        }

        bridgedToken.transferFrom(msg.sender, address(this), gas);

        // remove from pending redeems

        delete vaultIdToRedeemInformation[vaultId];
        //paying the relayer
        bridgedToken.transfer(msg.sender, withdrawGasFee);
        bridgedToken.transfer(pendingRedeem.outputAddress, DEPOSIT_AMOUNT - gas);
    }

    /**
     * @dev interface
     */

    function registerRedeem(uint256 vaultId, uint32 _otherChainId, uint256 gasFee) external {
        // attacker tries to use the proof in another chain
        // for now this is reverted, however this mechanism might need ot be handled more cautiously.

        if (!isRedeemed[vaultId]) {
            isRedeemed[vaultId] = true;
            return;
        } else {
            if (IBridgeModule(bridgeAddress).thisChainId() < _otherChainId) {
                vaultIdToRedeemInformation[vaultId].gasFee += gasFee;
                return;
            } else {
                delete vaultIdToRedeemInformation[vaultId];
                return;
            }
        }
    }
}
