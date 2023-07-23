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


    //TODO: clean the list of string (chain names)
    string[] chainNameList = [
        "Alfajores", "BSC Testnet", "Fuji", "Goerli", "Sepolia", "Mumbai", "Moonbase Alpha", "Moonbeam", "gnosistestnet", "neondevnet", "mantletestnet", "tenettestnet"
    ];
    //and a mapping string to identifier
    mapping(string => uint32) nameToChainId;
    mapping(string => address) nameToMailbox;
    mapping(string => bytes16) nameToAppId;
    mapping(string => address) nameToPaymaster;
    //string to token
    //iterate on the list to mint enough tokens

    //TODO: test sismo
    uint32 chainId;
    address _chainMailbox;

    CustomToken bertoken;
    HyperBridgeModule bridgeModule;

    function setUp() public {
        chainName = "neondevnet";//TODO
        //TODO: _setUpNameToAppId();
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
        nameToChainId["Sepolia"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        nameToMailbox["gnosis"] = 0x87529d295182f52677a04Fe2Fbc78dDFB34971AA;
        nameToChainId["neondevnet"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        nameToChainId["mantletestnet"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        nameToChainId["tenettestnet"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        nameToChainId["goerli"] = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
    }

    function _setUpChainNameToAppId() private {
        nameToAppId["goerli"] = bytes16(0x86f7dc8c2769b53552d88cca6e2cd94c);
        nameToAppId["gnosis"] = bytes16(0x4ad9f13225bde18e73a358219a573713);
        nameToAppId["Mumbai"] = bytes16(0x23d532b6f1b5a1811a929ead1c89d26f);
        nameToAppId["mantletestnet"] = bytes16(0x6bfd8840ad9488b56b0f5e9a8b77d086);
        nameToAppId["neondevnet"] = bytes16(0x29af9969b30280023bc416ba2ac010fa);
        nameToAppId["tenettestnet"] = bytes16(0x05936cd551f2964aaffca01afe81119e);
        nameToAppId["ZKSync"] = bytes16(0xdb4c58a023959dfc964eb9f8adf72b76);
    }

    function _setUpChainNameToPaymaster() private {
        nameToPaymaster["goerli"] = 0xF90cB82a76492614D07B82a7658917f3aC811Ac1;
        nameToPaymaster["gnosis"] = 0x56f52c0A1ddcD557285f7CBc782D3d83096CE1Cc;
    }
}
