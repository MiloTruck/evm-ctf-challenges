// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { IERC20 } from "./lib/IERC20.sol";
import { ERC20 } from "./lib/ERC20.sol";
import { FixedPointMathLib } from "./lib/FixedPointMathLib.sol";

/// @title SimpleVault
/// @notice The SimpleVault contract.
contract SimpleVault is ERC20 {
    using FixedPointMathLib for uint256;

    IERC20 public immutable GREY;

    uint256 public totalAssets;
    
    /**
     * @param _grey The GREY token address.
     */
    constructor(address _grey) ERC20("SimpleVault Token", "SV", 18) {
        GREY = IERC20(_grey);
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Stake GREY into the vault.
     *
     * @param assets  The amount of GREY the user wishes to stake.
     */
    function deposit(uint256 assets) external returns (uint256 shares) {
        shares = toSharesDown(assets);
        require(shares != 0, "zero shares");

        totalAssets += assets;
        _mint(msg.sender, shares);
        
        GREY.transferFrom(msg.sender, address(this), assets);
    }

    /**
     * @notice Withdraws staked GREY for shares.
     *
     * @param shares  The amount shares the user wishes to unstake.
     */
    function withdraw(uint256 shares) external returns (uint256 assets) {
        assets = toAssetsDown(shares);
        require(assets != 0, "zero assets");

        totalAssets -= assets;
        _burn(msg.sender, shares);

        GREY.transfer(msg.sender, assets);
    }

    /**
     * @notice Distribute GREY as rewards to stakers.
     *
     * @param assets  The amount of GREY to distribute as rewards.
     */
    function distributeRewards(uint256 assets) external {
        totalAssets += assets;
        GREY.transferFrom(msg.sender, address(this), assets);
    }

    // ======================================== VIEW FUNCTIONS ========================================

    /**
     * @notice Get the price of assets per share.
     *
     * @return The share price.
     */
    function sharePrice() external view returns (uint256) {
        return totalSupply == 0 ? 1e18 : totalAssets.divWadDown(totalSupply);
    }

    // ======================================== HELPERS ========================================

    function toSharesDown(uint256 assets) internal view returns (uint256) {
        if (totalAssets == 0 || totalSupply == 0) {
            return assets;
        }
        return assets.mulDivDown(totalSupply, totalAssets);
    }

    function toAssetsDown(uint256 shares) internal view returns (uint256) {
        return shares.mulDivDown(totalAssets, totalSupply);
    }
}