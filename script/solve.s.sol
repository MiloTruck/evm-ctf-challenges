// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Setup, Exploit} from "test/solutions/escrow.sol";

contract Solution is Script {
    Setup setup = Setup();

    function run() public {
        vm.startBroadcast();

        Exploit e = new Exploit(setup);
        e.solve();

        vm.stopBroadcast();
    }
}

// forge script script/solve.s.sol:Solution --rpc-url <rpc_url> --private-key <private_key> --broadcast
