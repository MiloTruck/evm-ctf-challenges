// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Setup as GHDSetup, Exploit as GHDExploit} from "test/solutions/greyhats-dollar.sol";
import {Setup as VVSetup, Exploit as VVExploit} from "test/solutions/voting-vault.sol";
import {Setup as SAVSetup, Exploit as SAVExploit} from "test/solutions/simple-amm-vault.sol";
import {Setup as ESetup, Exploit as EExploit} from "test/solutions/escrow.sol";
import {Setup as MSSetup, Exploit as MSExploit} from "test/solutions/meta-staking.sol";
import {Setup as GUSetup, Exploit as GUExploit} from "test/solutions/gnosis-unsafe.sol";

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

    function test_solve_meta_staking() public {
        (address addr, uint256 privateKey) = makeAddrAndKey("PLAYER");

        MSSetup setup = new MSSetup();
        MSExploit e = new MSExploit(setup, addr, privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, e.getTxHash());
        e.solve(v, r, s);

        assertTrue(setup.isSolved());
    }

    function test_solve_gnosis_unsafe() public {
        GUSetup setup = new GUSetup();
        GUExploit e = new GUExploit(setup);

        e.solvePart1();
        skip(1 minutes);
        e.solvePart2();

        assertTrue(setup.isSolved());
    }
}