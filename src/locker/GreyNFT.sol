// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "./lib/IERC20.sol";
import {ERC721} from "./lib/ERC721.sol";

/// @title GreyNFT
/// @notice ERC-721 token that can be minted by paying a fixed price in GREY tokens.
contract GreyNFT is ERC721 {
    address public immutable greyToken;
    uint256 public immutable nftPrice;

    /// @notice Deploys the GreyNFT contract.
    /// @param _greyToken Address of the GREY token.
    /// @param _nftPrice Cost (in the smallest unit of GREY) required to mint one NFT.
    constructor(address _greyToken, uint256 _nftPrice) ERC721("GreyNFT", "GREY") {
        greyToken = _greyToken;
        nftPrice = _nftPrice;
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /// @notice Mints a new NFT with the specified `id` in exchange for GREY.
    /// @param id The unique identifier of the NFT to mint.
    function mintNFT(uint256 id) external {
        _mint(msg.sender, id);
        IERC20(greyToken).transferFrom(msg.sender, address(this), nftPrice);
    }

    /// @notice Burns an NFT in exchange for GREY.
    /// @param id The unique identifier of the NFT to burn.
    function burnNFT(uint256 id) external {
        address owner = _ownerOf[id];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        _burn(id);
        IERC20(greyToken).transfer(msg.sender, nftPrice);
    }

    // ======================================== VIEW FUNCTIONS ========================================

    function tokenURI(uint256) public view override returns (string memory) {}
}
