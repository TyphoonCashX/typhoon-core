// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "hyperlane-monorepo/solidity/contracts/interfaces/IMailbox.sol";

import "./IExitNode.sol";

contract HyperBridge is Owned {
    uint32 chainId; 
    uint32[] private destinationList;
    mapping(uint32 => address) private destinationToRecipient;

    address public exitNode;
    IMailbox outbox;
    IMailbox inbox;
    string public lastMessage;

    event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);
    event SentMessage(uint32 destinationDomain, bytes32 recipient, bytes message);

    modifier onlyExitNode(){
        require(msg.sender == exitNode, "not enter node");
        _;
    }
    
    function addDestination(uint32 newdestination, address newDestinationRecipient) external onlyOwner {
        destinationList.push(newdestination);
        destinationToRecipient[newdestination] = newDestinationRecipient;
    }

    function removeDestination(uint32 _destination) external onlyOwner returns(bool){
        delete destinationToRecipient[_destination];
        for(uint256 i; i<destinationList.length; ++i){
            if (destinationList[i] == _destination){
                delete destinationList[i];
                return true;
            }
        }
        return false;
    }

    constructor(address _exitNode, uint32 _chainId, address _inbox, address _outbox, address admin) 
    Owned(msg.sender){
        exitNode = _exitNode;
        chainId = _chainId;
        outbox = IMailbox(_outbox);
        inbox = IMailbox(_inbox);
    }
    
    function broadcastRegister(
        uint256 newVaultId
    ) external onlyEnterNode {
        bytes memory encoded = abi.encodePacked(newVaultId);
        uint32 _destinationDomain; 
        address _destinationRecipient;
        for (uint i; i< destinationList.length; i++)
        {
            _destinationDomain = destinationList[i];
            _destinationRecipient = destinationToRecipient[_destinationDomain];
            bytes32 recipient = bytes32(uint256(uint160(_destinationRecipient)) << 96);
            outbox.dispatch(_destinationDomain, recipient, encoded);
            emit SentMessage(_destinationDomain, recipient, encoded);
        }
    }


    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external { //TODO have a modifier so only the bridge can call this function
        (uint256 vaultId) = abi.decode(_message, (uint256));
        //TODO: call EnterNode contract
        emit ReceivedMessage(_origin, _sender, _message);
    }

}