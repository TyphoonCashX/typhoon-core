// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "hyperlane-monorepo/solidity/contracts/interfaces/IMailbox.sol";

contract HyperBridge is Owned {

    uint32[] private destinationList;
    mapping(uint32 => address) private destinationRecipient;

    address public enterNode;
    IMailbox outbox;
    IMailbox inbox;
    bytes32 public lastSender;
    string public lastMessage;

    event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);
    event SentMessage(uint32 destinationDomain, bytes32 recipient, string message);

    modifier onlyEnterNode(){
        require(msg.sender == enterNode, "not enter node");
        _;
    }
    
    function editDestinationList(uint32[] calldata _destinationList, mapping(uint32 => address) calldata _destinationRecipient) external onlyOwner{
        destinationList = _destinationList;
        destinationRecipient = _destinationRecipient;
    }

    constructor(address _enterNode, address _inbox, address _outbox) 
    Owned(msg.sender){
        enterNode = _enterNode;

        outbox = IMailbox(_outbox);
        inbox = IMailbox(_inbox);
    }
    
    function broadcastRegister(
        uint32 _destinationDomain,
        bytes32 _recipient,
        uint256 newVaultId
    ) external onlyEnterNode {
        bytes memory encoded = abi.encode(newVaultId, uint256); 
        for (uint i; i< destinationList.length; i++)
        {
            uint32 _destinationDomain = destinationList[i];
            address _destinationRecipient = destinationRecipient[destinationList];
            outbox.dispatch(_destinationDomain, _destinationRecipient, encoded);
            emit SentMessage(_destinationDomain, _recipient, encoded);
        }
    }


    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external {
        lastSender = _sender;
        lastMessage = string(_message);
        emit ReceivedMessage(_origin, _sender, _message);
    }

}