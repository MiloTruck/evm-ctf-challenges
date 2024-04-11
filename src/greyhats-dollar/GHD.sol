// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { IERC20 } from "./lib/IERC20.sol";
import { FixedPointMathLib } from "./lib/FixedPointMathLib.sol";

/// @title GHD
/// @notice The GHD contract.
contract GHD {
    using FixedPointMathLib for uint256;

    string constant public name     = "GreyHats Dollar";
    string constant public symbol   = "GHD";
    uint8  constant public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    uint256 public constant ONE_YEAR = 365 days;

    IERC20 public immutable underlyingAsset;

    uint256 public immutable deflationRatePerSecond;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private shares;

    uint256 private totalShares;

    uint256 private conversionRate = FixedPointMathLib.WAD;

    uint256 private lastUpdated;

    /**
     * @param _underlyingAsset  The underlying asset token contract.
     * @param _deflationRate    The yearly deflation rate.
     */
    constructor(address _underlyingAsset, uint256 _deflationRate) {
        require(_deflationRate <= FixedPointMathLib.WAD, "deflation rate larger than 1e18");

        underlyingAsset = IERC20(_underlyingAsset);
        deflationRatePerSecond = _deflationRate / ONE_YEAR;
        lastUpdated = block.timestamp;
    }
    
    // ========================================= MODIFIERS ========================================

    /**
     * @notice Updates the conversion rate between GHD and the underlying asset.
     */
    modifier update {
        conversionRate = _conversionRate();
        lastUpdated = block.timestamp;
        
        _;
    }
    
    // ========================================= MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Mint GHD in exchange for the underlying asset.
     *
     * @param amount  The amount of GHD to mint.
     */
    function mint(uint256 amount) external update {
        uint256 _shares = _GHDToShares(amount, conversionRate, false);

        totalShares += _shares;
        shares[msg.sender] += _shares;

        underlyingAsset.transferFrom(msg.sender, address(this), amount);

        emit Transfer(address(0), msg.sender, amount);
    }

    /**
     * @notice Burn GHD in return for the underlying asset.
     *
     * @param amount  The amount of GHD to burn.
     */
    function burn(uint256 amount) external update {
        uint256 _shares = _GHDToShares(amount, conversionRate, true);

        totalShares -= _shares;
        shares[msg.sender] -= _shares;

        underlyingAsset.transfer(msg.sender, amount);

        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @notice Transfer GHD to another address.
     *
     * @param to      The address that receives GHD.
     * @param amount  The amount of GHD to transfer.
     * @return        Whether the transfer succeeded.
     */
    function transfer(address to, uint256 amount) external update returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    /**
     * @notice Transfer GHD from one address to another.
     *
     * @param from    The address that transfers GHD.
     * @param to      The address that receives GHD.
     * @param amount  The amount of GHD to transfer.
     * @return        Whether the transfer succeeded.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public update returns (bool) {
        if (from != msg.sender) allowance[from][msg.sender] -= amount;

        uint256 _shares = _GHDToShares(amount, conversionRate, false);
        uint256 fromShares = shares[from] - _shares;
        uint256 toShares = shares[to] + _shares;
        
        require(
            _sharesToGHD(fromShares, conversionRate, false) < balanceOf(from),
            "amount too small"
        );
        require(
            _sharesToGHD(toShares, conversionRate, false) > balanceOf(to),
            "amount too small"
        );

        shares[from] = fromShares;
        shares[to] = toShares;

        emit Transfer(from, to, amount);

        return true;
    }

    /**
     * @notice Grant another address allowance to transfer your GHD.
     *
     * @param spender  The address that gets the allowance.
     * @param amount   The amount of allowance to grant.
     * @return         Whether the approval succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    // ============================================ VIEW FUNCTIONS ===========================================

    /**
     * @notice Calculate the GHD balance of an address.
     *
     * @param user  The address that holds GHD.
     * @return      The GHD balance of the user.
     */
    function balanceOf(address user) public view returns (uint256) {
        return _sharesToGHD(shares[user], _conversionRate(), false);
    }
    
    /**
     * @notice Calculate the total supply of GHD.
     *
     * @return  The GHD total supply.
     */
    function totalSupply() external view returns (uint256) {
        return _sharesToGHD(totalShares, _conversionRate(), false);
    }

    // ============================================== HELPERS ===============================================

    function _conversionRate() internal view returns (uint256) {
        uint256 timePassed = block.timestamp - lastUpdated;
        uint256 multiplier = deflationRatePerSecond * timePassed;
        return conversionRate - conversionRate.mulWadDown(multiplier);
    }

    function _sharesToGHD(
        uint256 _shares, 
        uint256 _rate,
        bool roundUp
    ) internal pure returns (uint256) {
        return roundUp ? _shares.mulWadUp(_rate) : _shares.mulWadDown(_rate);
    }

    function _GHDToShares(
        uint256 _balance, 
        uint256 _rate,
        bool roundUp
    ) internal pure returns (uint256) {
        return roundUp ? _balance.divWadUp(_rate) : _balance.divWadDown(_rate);
    }
}