// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { GREY } from "./lib/GREY.sol";
import { VotingVault } from "./VotingVault.sol";
import { Treasury } from "./Treasury.sol";

contract Setup {
    bool public claimed;

    // GREY token
    GREY public grey;
    
    // Challenge contracts
    VotingVault public vault;
    Treasury public treasury;

    // Note: 1,000,000 votes required to pass a treasury proposal
    uint256 public constant MINIMUM_VOTES = 1_000_000e18;

    constructor() {
        // Deploy the GREY token contract
        grey = new GREY();

        // Deploy challenge contracts
        vault = new VotingVault(address(grey));
        treasury = new Treasury(address(vault), MINIMUM_VOTES);

        // Mint 10,000 GREY for setup
        grey.mint(address(this), 10_000e18);

        /*
        Treasury setup:
        - Deposit 10,000 GREY into reserves
        */
        grey.approve(address(treasury), 10_000e18);
        treasury.deposit(address(grey), 10_000e18);
    }

    // Note: Call this function to claim 1000 GREY for the challenge
    function claim() external {
        require(!claimed, "already claimed");
        claimed = true;
        
        grey.mint(msg.sender, 1000e18);
    }

    // Note: Challenge is solved when treasury has been drained
    function isSolved() external view returns (bool) {
        return grey.balanceOf(address(treasury)) == 0 && grey.balanceOf(msg.sender) >= 10_000e18;
    }
}