// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "hyperlane-monorepo/solidity/contracts/interfaces/IMailbox.sol";

import "hyperlane-monorepo/solidity/contracts/interfaces/IInterchainGasPaymaster.sol";
import "./IBridgeModule.sol";
import "./IExitNode.sol";

contract HyperBridgeModule is Owned, IBridgeModule {

    // state variable declaration
    uint32 public thisChainId;
    uint32[] private destinationList;
    mapping(uint32 => address) private chainToRecipient;
    //TODO: add conversion mapping
    mapping(uint32 => uint256) private chainToConversion;
    address public exitNode;
    IMailbox mailbox;
    string public lastMessage;
    IInterchainGasPaymaster igp;

    // events

    event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);
    event SentMessage(uint32 destinationDomain, bytes32 recipient, bytes message);

    // modifiers

    modifier onlyExitNode() {
        require(msg.sender == exitNode, "not enter node");
        _;
    }

    function _getConversion(uint32 chainId) private returns(uint256 rate){
        rate = chainToConversion[chainId];
        if (rate != 0){
            return rate;
        }
        return 1;
    } 

    /**
    @notice Adds an id to the destination chain and stores the id in the mapping
    @param newdestination : chain id of the new destination chain
    @param newDestinationRecipient : smart contract address on the destination chain where the funds will be deposited
     */

    function addDestination(uint32 newdestination, address newDestinationRecipient) external onlyOwner {
        destinationList.push(newdestination);
        chainToRecipient[newdestination] = newDestinationRecipient;
    }

    /**
    @notice remove the chain id of the destination chain
    @param _destination : chain id of the destination chain to be removed
     */

    function removeDestination(uint32 _destination) external onlyOwner returns (bool) {
        delete chainToRecipient[_destination];
        for (uint256 i; i < destinationList.length; ++i) {
            if (destinationList[i] == _destination) {
                delete destinationList[i];
                return true;
            }
        }
        return false;
    }

    /**
    @notice constructor
    @param _chainId : chain id of the exit node contract 
    @param _mailbox : address of the hyperlane contract
    @param admin : owner 
     */

    constructor(uint32 _chainId, address _mailbox, address payMaster, address admin) Owned(admin) {
        exitNode = msg.sender;
        thisChainId = _chainId;
        mailbox = IMailbox(_mailbox);
    }

    /**
    @dev interface
     */
    
    function broadcastRegister(uint256 newVaultId) external payable onlyExitNode {
        bytes memory encoded = abi.encodePacked(newVaultId);
        uint32 _destinationDomain;
        address _destinationRecipient;
        for (uint256 i; i < destinationList.length; i++) {
            _destinationDomain = destinationList[i];
            _destinationRecipient = chainToRecipient[_destinationDomain];
            bytes32 recipient = bytes32(uint256(uint160(_destinationRecipient)) << 96);
            bytes32 messageId = mailbox.dispatch(_destinationDomain, recipient, encoded);
            uint256 valueSent = 100000 * _getConversion(_destinationDomain);
            uint256 gasAmount = 100000;
            igp.payForGas{ value: valueSent}(
                messageId, // The ID of the message that was just dispatched
                _destinationDomain, // The destination domain of the message
                gasAmount, // 100k gas to use in the recipient's handle function
                msg.sender // refunds go to msg.sender, who paid the msg.value
            );
            emit SentMessage(_destinationDomain, recipient, encoded);
        }
    }

    /**
    @notice send messages
    @param _origin : chain id of the chain of origin 
    @param _sender : transactions sender 
    @param _message : broadcasted message
     */

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external {
        //TODO have a modifier so only the bridge can call this function
        //TODO: add a mapping from destination to recipient to verify that it is an actual recipient with a setter
        (uint256 vaultId, uint32 _otherChainId, uint256 gasFee) = abi.decode(_message, (uint256, uint32, uint256));
        IExitNode(exitNode).registerRedeem(vaultId, _otherChainId, gasFee);
        emit ReceivedMessage(_origin, _sender, _message);
    }

    //// modifier
    //TODO
    //modifier onlyBridgeAdapter(address caller) {
    //if (caller != hyperBridgeAddress){
    //revert isNotHyperplaneCaller(caller);
    //}
    //_;
    //}
}
