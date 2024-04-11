// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { IERC20 } from "./lib/IERC20.sol";
import { ERC20 } from "./lib/ERC20.sol";
import { FixedPointMathLib } from "./lib/FixedPointMathLib.sol";
import { ISimpleCallbacks } from "./interfaces/ISimpleCallbacks.sol";
import { SimpleVault } from "./SimpleVault.sol";

/// @title SimpleAMM
/// @notice The SimpleAMM contract.
contract SimpleAMM is ERC20 {
    using FixedPointMathLib for uint256;

    SimpleVault public immutable VAULT;

    IERC20 public immutable tokenX;
    IERC20 public immutable tokenY;

    uint256 public reserveX;
    uint256 public reserveY;

    uint256 public k;

    /**
     * @param _vault The vault address.
     */
    constructor(address _vault) ERC20("SimpleAMM Token", "SA", 18) {
        VAULT = SimpleVault(_vault);
        tokenX = IERC20(_vault);
        tokenY = VAULT.GREY();
    }

    // ========================================= MODIFIERS ========================================

    /**
     * @notice Enforces the x * y = k invariant
     */
    modifier invariant {
        _;
        require(computeK(reserveX, reserveY) >= k, "K");
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Deposit tokenX and tokenY into the pool for LP tokens.
     *
     * @param amountXIn  The amount of tokenX to deposit.
     * @param amountYIn  The amount of tokenY to deposit.
     */
    function allocate(
        uint256 amountXIn, 
        uint256 amountYIn
    ) external invariant returns (uint256 shares) {
        uint256 deltaK = computeK(amountXIn, amountYIn);
        shares = k == 0 ? deltaK : deltaK.mulDivDown(totalSupply, k);

        reserveX += amountXIn;
        reserveY += amountYIn;
        k += deltaK;

        _mint(msg.sender, shares);

        tokenX.transferFrom(msg.sender, address(this), amountXIn);
        tokenY.transferFrom(msg.sender, address(this), amountYIn);
    }

    /**
     * @notice Withdraw tokenX and tokenY from the pool by burning LP tokens.
     *
     * @param amountXOut  The amount of tokenX to withdraw.
     * @param amountYOut  The amount of tokenY to withdraw.
     */
    function deallocate(
        uint256 amountXOut,
        uint256 amountYOut
    ) external invariant returns (uint256 shares) {
        uint256 deltaK = computeK(amountXOut, amountYOut);
        shares = deltaK.mulDivUp(totalSupply, k);
        
        reserveX -= amountXOut;
        reserveY -= amountYOut;
        k -= deltaK;
        
        _burn(msg.sender, shares);

        tokenX.transfer(msg.sender, amountXOut);
        tokenY.transfer(msg.sender, amountYOut);
    }

    /**
     * @notice Swap either token for the other.
     *
     * @param swapXForY  Whether the swap is tokenX to tokenY, or vice versa.
     * @param amountIn   The amount of tokens to swap in.
     * @param amountOut  The amount of tokens to swap out.
     */
    function swap(bool swapXForY, uint256 amountIn, uint256 amountOut) external invariant {
        IERC20 tokenIn;
        IERC20 tokenOut;

        if (swapXForY) {
            reserveX += amountIn;
            reserveY -= amountOut;

            (tokenIn, tokenOut) = (tokenX, tokenY);
        } else {
            reserveX -= amountOut;
            reserveY += amountIn;

            (tokenIn, tokenOut) = (tokenY, tokenX);
        }

        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    }

    /**
     * @notice Flash loan either token from the pool.
     *
     * @param isTokenX  Whether the token to loan is tokenX or tokenY.
     * @param amount    The amount of tokens to loan.
     * @param data      Arbitrary data passed to the callback. 
     */
    function flashLoan(
        bool isTokenX, 
        uint256 amount, 
        bytes calldata data
    ) external invariant {
        IERC20 token = isTokenX ? tokenX : tokenY;
        token.transfer(msg.sender, amount);

        ISimpleCallbacks(msg.sender).onFlashLoan(amount, data);

        token.transferFrom(msg.sender, address(this), amount);
    }
    
    // ========================================= HELPERS ========================================

    function computeK(uint256 amountX, uint256 amountY) internal view returns (uint256) {
        uint256 price = VAULT.sharePrice();
        return amountX + amountY.divWadDown(price);
    }
}