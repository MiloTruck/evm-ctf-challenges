// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @title IFlashloanCallback 
/// @notice Interface for callbacks.
interface IFlashloanCallback {
    /**
     * @notice Callback called when a flashloan occurs.
     * @dev The callback is called only if data is not empty.  
     * @param _amount  The amount of supplied tokens.  
     * @param _data    Arbitrary data passed to the `flashLoan` function. 
     */
    function onFlashLoan(uint256 _amount, bytes calldata _data) external;
}