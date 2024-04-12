// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { ERC721 } from "./lib/ERC721.sol";
import { ClonesWithImmutableArgs } from "./lib/ClonesWithImmutableArgs.sol";
import { IEscrow } from "./interfaces/IEscrow.sol";

contract EscrowFactory is ERC721 {
    using ClonesWithImmutableArgs for address;

    error NotOwner();

    error AlreadyDeployed();

    address public immutable owner;

    address[] public escrowImpls;

    mapping(bytes32 => bool) public deployedParams; 

    constructor() ERC721("EscrowFactory NFT", "EFT") {
        owner = msg.sender;
    }
    
    // ======================================= PERMISSIONED FUNCTIONS ======================================

    /**
     * @notice Add an escrow implementation. Can only be called by the owner.
     *
     * @param impl  The address of the implementation to add.
     */
    function addImplementation(address impl) external {
        if (msg.sender != owner) revert NotOwner();
        
        escrowImpls.push(impl);
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Deploy an escrow.
     *
     * @param implId  The index of the escrow implementation in the escrowImpls array.
     * @param args    The immutable arguments to deploy the escrow with.  
     */
    function deployEscrow(
        uint256 implId,
        bytes memory args
    ) external returns (uint256 escrowId, address escrow) {
        // Get the hash of the (implId, args) pair
        bytes32 paramsHash = keccak256(abi.encodePacked(implId, args));

        // If an escrow with the same (implId, args) pair exists, revert
        if (deployedParams[paramsHash]) revert AlreadyDeployed();

        // Mark the (implId, args) pair as deployed
        deployedParams[paramsHash] = true;
        
        // Grab the implementation contract for the given implId
        address impl = escrowImpls[implId];

        // Clone the implementation contract and initialize it with the given parameters.
        escrow = impl.clone(abi.encodePacked(address(this), args));
        IEscrow(escrow).initialize();

        // Get the ID for the deployed escrow
        escrowId = IEscrow(escrow).escrowId();

        // Mint an ERC721 token to represent ownership of the escrow
        _mint(msg.sender, escrowId);
    }

    /**
     * @notice Permanently renounce ownership for an escrow.
     *
     * @param escrowId  The ID of the escrow.
     */
    function renounceOwnership(uint256 escrowId) external {
        if (msg.sender != ownerOf(escrowId)) revert NotOwner();

        _burn(escrowId);
    }

    // ========================================= VIEW FUNCTIONS ========================================

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }
}