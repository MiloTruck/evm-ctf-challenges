// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Setup, Exploit} from "test/solutions/voting-vault.sol";

contract Solution is Script {
    Setup setup = Setup(0xc8037ac2ab8ceCBFA8Abc6aeC14821481853746C);

    function run() public {
        vm.startBroadcast();

        Exploit e = new Exploit(setup);
        e.solvePart1();

        vm.stopBroadcast();

        console2.log(address(e));
    }
}

// forge script script/solve.s.sol:Solution --rpc-url <rpc_url> --private-key <private_key> --broadcast
