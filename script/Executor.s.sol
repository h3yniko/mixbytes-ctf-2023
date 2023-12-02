// SPDX-License-Identifier: UNLICENSED
pragma solidity <0.7.0;

import {Script, console2} from "forge-std/Script.sol";
import "../src/Executor.sol";

contract ExecutorTestnet is Script {
    function setUp() public {}
    
    function run() public {
        vm.broadcast();

        Executor executorOrig = new Executor();
        Proxy proxy = new Proxy(address(executorOrig));
        Executor executorProxy = Executor(address(proxy));
        ExecutorTest test = new ExecutorTest();

        ExecutorEbalka ebalka = new ExecutorEbalka();
        executorProxy.execute(address(ebalka));
        executorOrig.execute(address(ebalka));

        vm.roll(block.number + 1);

        try executorProxy.execute(address(test)) {
            console.log('test 1 failed');
        } catch {
            console.log('test 1 passed');
        }

        try executorOrig.execute(address(test)) {
            console.log('test 2 failed');
        } catch {
            console.log('test 2 passed');
        }
    }
}

contract ExecutorMainnet is Script {
    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        //  memory - 0x000000000000000000000000c4b95ad8c5dbabf90896b37a95a4ef4ed61efc47;
        Executor executorProxy = Executor(0xdEC65cF5ae7b09A4bcc678336F795Ff99EEcf5C1);
        console.log(executorProxy.owner());
        Executor executorOrig = Executor(0x54e8fFb212C3c289710BEBd3230FD6CB91121E34);
        console.log(executorOrig.owner());
        ExecutorEbalka ebalka = new ExecutorEbalka();

        executorProxy.execute(address(ebalka));
        executorOrig.execute(address(ebalka));
    }
}