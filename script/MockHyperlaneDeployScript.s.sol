// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/EnterNode.sol";
import "../src/Mock/ExitNodeMock.sol";
import "../src/HyperBridgeModule.sol";

import "../src/customERC20/customToken.sol";

contract HyperlaneDeployScript is Script {
    address[] usersAddressList = [0x2CCa7aB1189d82073E48081e36F7B080f16607dB, 0x1C7D716e3afd558F3665b597e092f3C7d7E6C782];

    EnterNode enterNode;
    ExitNode exitNode;
    string chainName;


    string[] chainNameList = [
        "Fuji", "Goerli", "Sepolia", "Mumbai", "Moonbeam", "gnosis", "neondevnet", "mantletestnet", "tenettestnet", "ZKSync", "Linea", "PolygonZkEVM", "ZetaChain"
    ];
    //and a mapping string to identifier
    mapping(string => uint32) nameToChainId;
    mapping(string => address) nameToMailbox;
    mapping(string => bytes16) nameToAppId;
    mapping(string => address) nameToPaymaster;


    CustomToken bertoken;
    HyperBridgeModule bridgeModule;

    function setUp() public {
        chainName = "PolygonZkEVM";//TODO
        _setUpNameToChainId();
        _setUpChainNameToAppId();
        _setUpChainNameToPaymaster();
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        bertoken = new CustomToken("Berto", "BERTO");
        //mint tokens to every user address
        for (uint i; i<usersAddressList.length; ++i){
            bertoken.mint(usersAddressList[i], 1000 * 10**18);
        }
    }

    function run() public {
        enterNode = new EnterNode();
        exitNode = new ExitNode(address(bertoken), nameToAppId[chainName], nameToChainId[chainName], nameToMailbox[chainName], nameToPaymaster[chainName]);
        bertoken.mint(address(exitNode), 1000 * 10**18);
        console.log("Exit Node deployed");
        bridgeModule = HyperBridgeModule(exitNode.bridgeModuleAddress());
    }

    function _addDestination(uint32 newdestination, address newDestinationRecipient) private {
        bridgeModule.addDestination(newdestination, newDestinationRecipient);
    }

    function _setUpNameToChainId() private {
        nameToChainId["Mumbai"] = 80001;
        nameToChainId["Sepolia"] = 11155111;
        nameToChainId["gnosis"] = 100;
        nameToChainId["neondevnet"] = 245022926;
        nameToChainId["mantletestnet"] = 5001;
        nameToChainId["tenettestnet"] = 155;
        nameToChainId["goerli"] = 5;
        nameToChainId["PolygonZkEVM"] = 1422;
        nameToChainId["Linea"] = 59140;
        nameToChainId["ZKSync"] = 280;
    }
    
    function _setUpNameToMailbox() private {
        nameToMailbox["Mumbai"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        nameToMailbox["Sepolia"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        nameToMailbox["gnosis"] = 0x87529d295182f52677a04Fe2Fbc78dDFB34971AA;
        nameToMailbox["neondevnet"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        nameToMailbox["mantletestnet"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        nameToMailbox["tenettestnet"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        nameToMailbox["goerli"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        nameToMailbox["Polygon"] =0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70;
    }

    function _setUpChainNameToAppId() private {
        nameToAppId["goerli"] = bytes16(0x86f7dc8c2769b53552d88cca6e2cd94c);
        nameToAppId["gnosis"] = bytes16(0x4ad9f13225bde18e73a358219a573713);
        nameToAppId["Mumbai"] = bytes16(0x23d532b6f1b5a1811a929ead1c89d26f);
        nameToAppId["Polygon"] = bytes16(0x8dff3c2056749b30ce4c0f5d416e9dfe);
        nameToAppId["mantletestnet"] = bytes16(0x6bfd8840ad9488b56b0f5e9a8b77d086);
        nameToAppId["neondevnet"] = bytes16(0x29af9969b30280023bc416ba2ac010fa);
        nameToAppId["tenettestnet"] = bytes16(0x05936cd551f2964aaffca01afe81119e);
        nameToAppId["ZKSync"] = bytes16(0xdb4c58a023959dfc964eb9f8adf72b76);
    }

    function _setUpChainNameToPaymaster() private {
        nameToPaymaster["goerli"] = 0x8f9C3888bFC8a5B25AED115A82eCbb788b196d2a;
        nameToPaymaster["gnosis"] = 0x6cA0B6D22da47f091B7613223cD4BB03a2d77918;
        nameToPaymaster["Polygon"] = 0x6cA0B6D22da47f091B7613223cD4BB03a2d77918;
    }
}
