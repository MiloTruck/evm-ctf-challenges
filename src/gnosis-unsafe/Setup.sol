// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { GREY } from "./lib/GREY.sol";
import { Safe } from "./Safe.sol";

contract Setup {
    bool public claimed;

    // GREY token
    GREY public grey;
    
    // Challenge contracts
    Safe public safe;

    constructor() {
        // Deploy the GREY token contract
        grey = new GREY();

        // Deploy safe with dead owners
        safe = new Safe([address(0x1337), address(0xdead), address(0xdeadbeef)]);

        // Mint 10,000 GREY to the safe
        grey.mint(address(safe), 10_000e18);
    }

    // Note: Call this function to claim 1000 GREY for the challenge
    function claim() external {
        require(!claimed, "already claimed");
        claimed = true;
        
        grey.mint(msg.sender, 1000e18);
    }

    // Note: Challenge is solved when the safe has been drained
    function isSolved() external view returns (bool) {
        return grey.balanceOf(address(safe)) == 0 && grey.balanceOf(msg.sender) >= 10_000e18;
    }
}