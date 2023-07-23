// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/EnterNode.sol";
import "../src/ExitNode.sol";
import "../src/HyperBridgeModule.sol";

import "../src/customERC20/customToken.sol";

contract HyperlaneDeployScript is Script {
    address[] usersAddressList = [0x2CCa7aB1189d82073E48081e36F7B080f16607dB, 0x1C7D716e3afd558F3665b597e092f3C7d7E6C782];

    EnterNode enterNode;
    ExitNode exitNode;
    string chainName;


    //TODO: clean the list of string (chain names)
    string[] chainNameList = [
        "Alfajores", "BSC Testnet", "Fuji", "Goerli", "Sepolia", "Mumbai", "Moonbase Alpha", "Moonbeam", "gnosistestnet", "neondevnet", "mantletestnet", "tenettestnet"
    ];
    //and a mapping string to identifier
    mapping(string => uint32) nameToChainId;
    mapping(string => address) nameToMailbox;
    mapping(string => bytes16) nameToAppId;
    //string to token
    //iterate on the list to mint enough tokens

    //TODO: test sismo
    uint32 chainId;
    address _chainMailbox;

    CustomToken bertoken;
    HyperBridgeModule bridgeModule;

    function setUp() public {
        chainName = "Mumbai";//TODO
        //TODO: _setUpNameToAppId();
        _setUpNameToChainId();
        _setUpChainNameToAppId();
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        bertoken = new CustomToken("Berto", "BERTO");
        //mint tokens to every user address
        for (uint i; i<usersAddressList.length; ++i){
            bertoken.mint(usersAddressList[i], 1000 * 10**18);
        }
    }

    function run() public {
        enterNode = new EnterNode();
        exitNode = new ExitNode(address(bertoken), nameToAppId[chainName], nameToChainId[chainName], nameToMailbox[chainName]);
        console.log("Exit Node deployed");
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
    
    function _setUpNameToMailbox() private {
        nameToMailbox["Mumbai"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        //nameToChainId["Sepolia"] = 11155111;
        nameToMailbox["gnosistestnet"] = 0x87529d295182f52677a04Fe2Fbc78dDFB34971AA;
        //nameToChainId["neondevnet"] = 245022926;
        //nameToChainId["mantletestnet"] = 5001;
        //nameToChainId["tenettestnet"] = 155;
        //nameToChainId["goerli"] = 5;
    }

    function _setUpChainNameToAppId() private {
        nameToAppId["goerli"] = bytes16(0x86f7dc8c2769b53552d88cca6e2cd94c);
    }
}
