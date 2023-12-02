// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import "../src/Bucket.sol";

contract Testnet is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        Buckets buckets = new Buckets();
        BucketsProxy proxy = new BucketsProxy(address(buckets), 1337);

        new BucketEbalka{value: 1}(payable(address(proxy)));

        vm.stopBroadcast();
    }
}

contract Mainnet is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        new BucketEbalka{value: 1}(payable(address(0xD23AdBC8871b5DAee3F7A8b2f874E01538B11d2C)));

        vm.stopBroadcast();
    }
}