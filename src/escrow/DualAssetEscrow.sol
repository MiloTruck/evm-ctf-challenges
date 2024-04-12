// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { IERC20 } from "./lib/IERC20.sol";
import { Clone } from "./lib/Clone.sol";
import { IEscrow } from "./interfaces/IEscrow.sol";
import { IEscrowFactory } from "./interfaces/IEscrowFactory.sol";

contract DualAssetEscrow is IEscrow, Clone {
    error NotOwner();

    error AlreadyInitialized();

    error CalldataTooLong();

    error InsufficientETH();

    error ETHTransferFailed();

    address public constant ETH_ADDRESS = address(0);
    
    bytes32 public constant IDENTIFIER = keccak256("ESCROW_SINGLE_ASSET");

    uint256 public escrowId;

    mapping(address => uint256) public reserves;

    bool private initialized;

    /**
     * @notice Initialize the escrow.
     */
    function initialize() external {
        if (initialized) revert AlreadyInitialized();
        
        /*
        Revert if calldata size is too large, which signals `args` contains more data than expected.

        This is to prevent adding extra bytes to `args` that results in a different `paramsHash` 
        in the factory.

        Expected length is 66:
        - 4 bytes for selector
        - 20 bytes for factory address
        - 20 bytes for tokenX address
        - 20 bytes for tokenY address
        - 2 bytes for CWIA length
        */
        if (msg.data.length > 66) revert CalldataTooLong();
        
        initialized = true;

        (address factory, address tokenX, address tokenY) = _getArgs();
        escrowId = uint256(keccak256(abi.encodePacked(IDENTIFIER, factory, tokenX, tokenY)));
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Deposit tokenX or tokenY into the escrow.
     *
     * @param isTokenX  Whether the asset to deposit is tokenX.
     * @param amount    The amount of assets to deposit.  
     */
    function deposit(bool isTokenX, uint256 amount) external payable {
        if (msg.sender != owner()) revert NotOwner();

        (, address tokenX, address tokenY) = _getArgs();
        address token = isTokenX ? tokenX : tokenY;

        reserves[token] += amount;

        if (token == ETH_ADDRESS) {
            if (msg.value != amount) revert InsufficientETH();
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
    }

    /**
     * @notice Withdraw tokenX or tokenY from the escrow.
     *
     * @param isTokenX  Whether the asset to withdraw is tokenX.
     * @param amount    The amount of assets to withdraw.  
     */
    function withdraw(bool isTokenX, uint256 amount) external {
        if (msg.sender != owner()) revert NotOwner();

        (, address tokenX, address tokenY) = _getArgs();
        address token = isTokenX ? tokenX : tokenY;

        reserves[token] -= amount;

        if (token == ETH_ADDRESS) {
            (bool success, ) = msg.sender.call{ value: amount }("");
            if (!success) revert ETHTransferFailed();
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    // ========================================= VIEW FUNCTIONS ========================================

    /**
     * @notice The escrow owner, based on who holds the EscrowFactory NFT.
     */
    function owner() public view returns (address) {
        (address factory, , ) = _getArgs();
        return IEscrowFactory(factory).ownerOf(escrowId);
    }

    // ========================================= HELPERS ========================================

    function _getArgs() internal pure returns (address factory, address tokenX, address tokenY) {
        factory = _getArgAddress(0);
        tokenX = _getArgAddress(20);
        tokenY = _getArgAddress(40);
    }
}