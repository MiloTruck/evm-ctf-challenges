// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { GREY } from "./lib/GREY.sol";
import { Relayer } from "./Relayer.sol";
import { Staking } from "./Staking.sol";

contract Setup {
    bool public claimed;

    // GREY token
    GREY public grey;
    
    // Challenge contracts
    Relayer public relayer;
    Staking public staking;

    constructor() {
        // Deploy the GREY token contract
        grey = new GREY();

        // Deploy relayer and staking contracts
        relayer = new Relayer();
        staking = new Staking(address(grey), address(relayer));

        // Mint 10,000 GREY to this address and stake them
        grey.mint(address(this), 10_000e18);
        grey.approve(address(staking.vault()), 10_000e18);
        staking.stake(10_000e18);
    }

    // Note: Call this function to claim 1000 GREY for the challenge
    function claim() external {
        require(!claimed, "already claimed");
        claimed = true;
        
        grey.mint(msg.sender, 1000e18);
    }

    // Note: Challenge is solved when the vault has been drained
    function isSolved() external view returns (bool) {
        return grey.balanceOf(address(staking.vault())) == 0 && grey.balanceOf(msg.sender) >= 10_000e18;
    }
}