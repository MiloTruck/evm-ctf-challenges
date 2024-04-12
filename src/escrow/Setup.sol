// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { GREY } from "./lib/GREY.sol";
import { EscrowFactory } from "./EscrowFactory.sol";
import { DualAssetEscrow } from "./DualAssetEscrow.sol";

contract Setup {
    bool public claimed;

    // GREY token
    GREY public grey;
    
    // Challenge contracts
    EscrowFactory public factory;

    // Note: This is the address and ID of the escrow to drain
    address public escrow;
    uint256 public escrowId;

    constructor() {
        // Deploy the GREY token contract
        grey = new GREY();

        // Deploy challenge contracts
        factory = new EscrowFactory();

        // Mint 10,000 GREY for setup
        grey.mint(address(this), 10_000e18);

        // Add DualAssetEscrow implementation
        address impl = address(new DualAssetEscrow());
        factory.addImplementation(impl);

        // Deploy a DualAssetEscrow
        (escrowId, escrow) = factory.deployEscrow(
            0,  // implId = 0
            abi.encodePacked(address(grey), address(0)) // tokenX = GREY, tokenY = ETH
        );

        // Deposit 10,000 GREY into the escrow
        grey.approve(address(escrow), 10_000e18);
        DualAssetEscrow(escrow).deposit(true, 10_000e18);

        // Renounce ownership of the escrow
        factory.renounceOwnership(escrowId);
    }

    // Note: Call this function to claim 1000 GREY for the challenge
    function claim() external {
        require(!claimed, "already claimed");
        claimed = true;
        
        grey.mint(msg.sender, 1000e18);
    }

    // Note: Challenge is solved when the escrow has been drained
    function isSolved() external view returns (bool) {
        return grey.balanceOf(address(escrow)) == 0 && grey.balanceOf(msg.sender) >= 10_000e18;
    }
}