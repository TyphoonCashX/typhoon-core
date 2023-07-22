// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IExitNode.sol";
import "sismo-connect-solidity/SismoConnectLib.sol";
import "sismo-connect-solidity/utils/SismoConnectHelper.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "solmate/auth/Owned.sol";
import "./HyperBridgeModule.sol";
import "./IBridgeModule.sol";

contract ExitNode is IExitNode, SismoConnect, Owned {
    using SismoConnectHelper for SismoConnectVerifiedResult;

    bool private _isImpersonationMode = true;

    // constants
    uint8 public constant N_BLOCKS_DELAY = 1;
    address public constant ZERO_ADDRESS = address(0x0);
    uint256 public constant DEPOSIT_AMOUNT = 10 * 10 ** 18;

    //final
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

    // mapping that associates vaultId to pending redeem information
    mapping(uint256 => PendingRedeem) public vaultIdToRedeemInformation;

    // constructor

    constructor(address _tokenAddress, bytes16 _appId, uint32 _chainId, address _mailbox)
        SismoConnect(buildConfig(_appId, _isImpersonationMode))
        Owned(msg.sender)
    {
        tokenAddress = _tokenAddress;
        _deployHyperBridgeModule(_chainId, _mailbox);
    }

    function _deployHyperBridgeModule(uint32 _chainId, address _mailbox) private onlyOwner {
        bridgeModuleAddress = address(new HyperBridgeModule(_chainId, _mailbox, msg.sender));
    }

    /**
     *  @notice Function called to enter the pending registry, awaiting withdrawal
     *  @param response : generated proof deposited for verification
     *  @param redeemGasFee : gas fee for redeeming, delegated to the relayer
     *  @param outputAddress : output address for the bridge, where the tokens will be deposited
     */

    //TODO: make this payable to get the money for the bridging
    function redeem(bytes memory response, uint256 redeemGasFee, address outputAddress) external {
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

        // This is the moment where we might take you money.

        if (isRedeemed[vaultId]) {
            revert isAlreadyClaimed(vaultId);
        }

        isRedeemed[vaultId] = true;

        vaultIdToRedeemInformation[vaultId] = PendingRedeem({
            vaultId: vaultId,
            outputAddress: outputAddress,
            releaseTimestamp: block.timestamp + N_BLOCKS_DELAY,
            gasFee: redeemGasFee //TODO: redeemGasFee < Max_Withdraw
        });

        //TODO: broadcast
    }

    /**
     * @notice withdraw funds from the bridge
     * @param withdrawGasFee : withdrawal gas fees delegated to the relayer.
     * @param vaultId : vaultId of the user
     */

    function withdraw(uint256 withdrawGasFee, uint256 vaultId) external {
        //TODO: have a signature for the withdrawn gasfee
        // verify if the vault Id is in the pending registry
        PendingRedeem storage pendingRedeem = vaultIdToRedeemInformation[vaultId];
        uint256 gas = pendingRedeem.gasFee + withdrawGasFee; //TODO: gasFee < maxWithdraw
        IERC20 bridgedToken = IERC20(tokenAddress);

        if (keccak256(abi.encode(pendingRedeem)) == nullRedeemInformation) {
            revert notInPendingList(vaultId);
        }

        bridgedToken.transferFrom(msg.sender, address(this), gas);

        // remove from pending redeems

        delete vaultIdToRedeemInformation[vaultId];

        bridgedToken.transfer(pendingRedeem.outputAddress, DEPOSIT_AMOUNT - gas);
    }

    /**
     * @notice broadcast to other chains that claim has already been made
     * @param vaultId : vaultId to the user.
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
