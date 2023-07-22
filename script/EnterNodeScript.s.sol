// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/EnterNode.sol";
import "../src/ExitNode.sol";
import "../src/HyperBridgeModule.sol";
import "openzeppelin/token/ERC20/ERC20.sol";

contract HyperlaneDeployScript is Script {
    bytes16 appId; //TODO: set appId
    EnterNode enterNode;
    ExitNode exitNode;
    //TODO: create a list of string (chain names)
    string[] chainNameList = [
        "Alfajores", "BSC Testnet", "Fuji", "Goerli", "Sepolia", "Mumbai", "Moonbase Alpha", "Moonbeam", "gnosistestnet", "neondevnet", "mantletestnet", "tenettestnet"
    ];
    //and a mapping string to identifier
    mapping(string => uint32) nameToChainId;
    //string to token
    //iterate on the list to mint enough tokens

    //TODO: test sismo
    uint32 chainId;
    address _chainInbox;
    address _chainOutbox;

    ERC20 bertoken;
    HyperBridgeModule bridgeModule;



    function setUp() public {
        _setUpChainNameToAppId();
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        bertoken = new ERC20("Berto", "BERTO");
    }

    function run() public {
        enterNode = new EnterNode();
        exitNode = new ExitNode(address(bertoken), appId, chainId, _chainInbox, _chainOutbox);
        bridgeModule = HyperBridgeModule(exitNode.bridgeModuleAddress());
    }

    function _addDestination(uint32 newdestination, address newDestinationRecipient) private {
        bridgeModule.addDestination(newdestination, newDestinationRecipient);
    }

    function _setUpNameToChainId() private {
        nameToChainId["Mumbai"] = 80001;
        nameToChainId["Sepolia"] = 11155111;
        nameToChainId["gnosistestnet"] = 10200;
        nameToChainId["neondevnet"] = 245022926;
        nameToChainId["mantletestnet"] = 5001;
        nameToChainId["tenettestnet"] = 155;
        nameToChainId["goerli"] = 5;
    }

    function setUpChainNameToAppId() private {
        
    }
}
