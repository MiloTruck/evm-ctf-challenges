// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GREY} from "./lib/GREY.sol";
import {Race} from "./Race.sol";

contract Setup {
    // Challenge contracts
    GREY public grey;
    Race public race;

    // Whether GREY has been claimed
    bool public claimed;

    constructor() {
        grey = new GREY();
        race = new Race(address(grey));

        // Mint 1000 GREY for setup
        grey.mint(address(this), 1000e18);

        // Create a race which starts in a year
        grey.approve(address(race), 1000e18);
        race.createRace(1000e18, 365 days, 100e18);
    }

    // Note: Call this function to claim 500 GREY for the challenge
    function claim() external {
        require(!claimed, "already claimed");
        claimed = true;

        grey.mint(msg.sender, 500e18);
    }

    // Note: Challenge is solved when you have at least 1500 GREY
    function isSolved() external view returns (bool) {
        return grey.balanceOf(msg.sender) >= 1500e18;
    }
}
