// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GREY} from "./lib/GREY.sol";
import {GreyNFT} from "./GreyNFT.sol";
import {Locker} from "./Locker.sol";

contract Setup {
    // Challenge contracts
    GREY public grey;
    GreyNFT public greyNFT;
    Locker public locker;

    // Whether GREY has been claimed
    bool public claimed;

    constructor() {
        grey = new GREY();
        greyNFT = new GreyNFT(address(grey), 100e18); // Each NFT costs 100 GREY
        locker = new Locker();

        // Mint 100 GREY for setup
        grey.mint(address(this), 100e18);

        // Mint NFT 1337
        grey.approve(address(greyNFT), 100e18);
        greyNFT.mintNFT(1337);

        // Lock NFT 1337 in Locker
        greyNFT.approve(address(locker), 1337);
        locker.lockNFT(address(greyNFT), 1337, 365 days, address(0xdead));
    }

    // Note: Call this function to claim 500 GREY for the challenge
    function claim() external {
        require(!claimed, "already claimed");
        claimed = true;

        grey.mint(msg.sender, 500e18);
    }

    // Note: Challenge is solved when you own NFT 1337
    function isSolved() external view returns (bool) {
        return greyNFT.ownerOf(1337) == msg.sender;
    }
}
