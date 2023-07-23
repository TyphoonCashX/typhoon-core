// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/HyperBridgeModule.sol";

contract HyperlaneDestinationsScript is Script {
    string[] chainNameList = [
        "Alfajores", "BSC Testnet", "Fuji", "Goerli", "Sepolia", "Mumbai", "Moonbase Alpha", "Moonbeam", "gnosistestnet", "neondevnet", "mantletestnet", "tenettestnet"
    ];
    string chosenChain;
    mapping(string => address) nameToBridge;
    mapping(string => address) nameToRecipient;
    mapping(string => uint32) nameToChainId;


    function setUp() public {
        chosenChain = "";//TODO
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    }

    function run() public {
        HyperBridgeModule bridgeModule = HyperBridgeModule(nameToRecipient[chosenChain]);

        for(uint i; i<chainNameList.length; ++i){
            string memory chain = chainNameList[i];
            if (keccak256(abi.encode(chain)) != keccak256(abi.encode(chosenChain))){
                bridgeModule.addDestination(nameToChainId[chain], nameToRecipient[chain]);
            }
        }
    }

    function _setUpNameToRecipient() private {
        //nameToRecipient["Mumbai"] = 80001;
        //nameToRecipient["Sepolia"] = 11155111;
        //nameToRecipient["gnosistestnet"] = 10200;
        //nameToRecipient["neondevnet"] = 245022926;
        //nameToRecipient["mantletestnet"] = 5001;
        //nameToRecipient["tenettestnet"] = 155;
        //nameToRecipient["goerli"] = 5;
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
}