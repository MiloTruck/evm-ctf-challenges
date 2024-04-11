// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { GREY } from "./GREY.sol";
import { SimpleVault } from "./SimpleVault.sol";
import { SimpleAMM } from "./SimpleAMM.sol";

contract Setup {
    bool public claimed;

    // GREY token
    GREY public grey;
    
    // Challenge contracts
    SimpleVault public vault;
    SimpleAMM public amm;

    constructor() {
        // Deploy the GREY token contract
        grey = new GREY();

        // Deploy challenge contracts
        vault = new SimpleVault(address(grey));
        amm = new SimpleAMM(address(vault));

        // Mint 4000 GREY for setup
        grey.mint(address(this), 4000e18);

        /* 
        SimpleVault setup:
        - Deposit 1000 GREY into the vault
        - Distribute 1000 GREY as rewards
        */
        grey.approve(address(vault), 2000e18);
        vault.deposit(1000e18);
        vault.distributeRewards(1000e18);

        /*
        SimpleAMM setup:
        - Allocate 1000 SV and 2000 GREY into the pool
        */
        vault.approve(address(amm), 1000e18);
        grey.approve(address(amm), 2000e18);
        amm.allocate(1000e18, 2000e18);
    }

    // Note: Call this function to claim 1000 GREY for the challenge
    function claim() external {
        require(!claimed, "already claimed");
        claimed = true;
        
        grey.mint(msg.sender, 1000e18);
    }

    // Note: Challenge is solved when you have at least 3000 GREY
    function isSolved() external view returns (bool) {
        return grey.balanceOf(msg.sender) >= 3000e18;
    }
}