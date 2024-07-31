// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Setup, Exploit} from "test/solutions/gnosis-unsafe.sol";

contract Solution is Script {
    Setup setup = Setup(0x8f0A388dA94131eb66CB51DD81bD2e6E791dA9D8);

    function run() public {
        vm.startBroadcast();

        Exploit e = Exploit(0x29604d731cF2350E74623b29e4195aE11043c611);
        e.solvePart2();
        // console2.log(address(e));

        vm.stopBroadcast();
    }
}

// forge script script/solve.s.sol:Solution --rpc-url <rpc_url> --private-key <private_key> --broadcast
