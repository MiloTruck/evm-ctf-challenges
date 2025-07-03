// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Setup as RationalSetup, Exploit as RationalExploit} from "test/solutions/rational.sol";
import {Setup as LaunchpadSetup, Exploit as LaunchpadExploit} from "test/solutions/launchpad.sol";
import {Setup as LockerSetup, Exploit as LockerExploit} from "test/solutions/locker.sol";
import {Setup as RaceSetup, Exploit as RaceExploit} from "test/solutions/race.sol";

contract Solution is Test {
    function test_solve_rational() public {
        RationalSetup setup = new RationalSetup();
        RationalExploit e = new RationalExploit(setup);

        e.solve();

        assertTrue(setup.isSolved());
    }

    function test_solve_launchpad() public {
        LaunchpadSetup setup = new LaunchpadSetup();
        LaunchpadExploit e = new LaunchpadExploit(setup);

        e.solve();

        assertTrue(setup.isSolved());
    }

    function test_solve_locker() public {
        LockerSetup setup = new LockerSetup();
        LockerExploit e = new LockerExploit(setup);

        e.solve();

        assertTrue(setup.isSolved());
    }

    function test_solve_race() public {
        RaceSetup setup = new RaceSetup();
        RaceExploit e = new RaceExploit(setup);

        e.solvePart1();
        skip(1 seconds);
        e.solvePart2();

        assertTrue(setup.isSolved());
    }
}