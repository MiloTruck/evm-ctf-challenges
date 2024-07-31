// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Setup, Exploit} from "test/solutions/meta-staking.sol";

contract Solution is Test {
    function test_solve_meta_staking() public {
        (address addr, uint256 privateKey) = makeAddrAndKey("PLAYER");

        Setup setup = new Setup();
        Exploit e = new Exploit(setup, addr, privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, e.getTxHash());
        e.solve(v, r, s);

        assertTrue(setup.isSolved());
    }
}