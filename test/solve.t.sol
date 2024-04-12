// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Setup as GHDSetup, Exploit as GHDExploit} from "test/solutions/greyhats-dollar.sol";
import {Setup as VVSetup, Exploit as VVExploit} from "test/solutions/voting-vault.sol";
import {Setup as SAVSetup, Exploit as SAVExploit} from "test/solutions/simple-amm-vault.sol";
import {Setup as ESetup, Exploit as EExploit} from "test/solutions/escrow.sol";

contract Solution is Test {
    function test_solve_greyhats_dollar() public {
        GHDSetup setup = new GHDSetup();
        GHDExploit e = new GHDExploit(setup);

        e.solve();

        assertTrue(setup.isSolved());
    }

    function test_solve_voting_vault() public {
        VVSetup setup = new VVSetup();
        VVExploit e = new VVExploit(setup);

        e.solvePart1();
        vm.roll(block.number + 1);
        e.solvePart2();

        assertTrue(setup.isSolved());
    }

    function test_solve_simple_amm_vault() public {
        SAVSetup setup = new SAVSetup();
        SAVExploit e = new SAVExploit(setup);

        e.solve();
        
        assertTrue(setup.isSolved());
    }

    function test_solve_escrow() public {
        ESetup setup = new ESetup();
        EExploit e = new EExploit(setup);

        e.solve();
        
        assertTrue(setup.isSolved());
    }
}