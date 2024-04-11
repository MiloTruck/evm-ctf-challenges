// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { GREY } from "./lib/GREY.sol";
import { GHD } from "./GHD.sol";

contract Setup {
    bool public claimed;

    // GREY token
    GREY public grey;
    
    // Challenge contracts
    GHD public ghd;
    
    // Note: Deflation rate is set to 3% per year
    uint256 public constant DEFLATION_RATE = 0.03e18;

    constructor() {
        // Deploy the GREY token contract
        grey = new GREY();

        // Deploy challenge contracts
        ghd = new GHD(address(grey), DEFLATION_RATE);
    }

    // Note: Call this function to claim 1000 GREY for the challenge
    function claim() external {
        require(!claimed, "already claimed");
        claimed = true;
        
        grey.mint(msg.sender, 1000e18);
    }

    // Note: Challenge is solved when you have at least 50,000 GHD
    function isSolved() external view returns (bool) {
        return ghd.balanceOf(msg.sender) >= 50_000e18;
    }
}