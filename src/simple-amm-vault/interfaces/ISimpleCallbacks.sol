// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @title ISimpleCallbacks 
/// @notice Interface for callbacks.
interface ISimpleCallbacks {
    /**
     * @notice Callback called when a deposit occurs.
     * @dev The callback is called only if data is not empty.  
     * @param _assets  The amount of supplied assets.  
     * @param _data    Arbitrary data passed to the `flashLoan` function. 
     */
    function onFlashLoan(uint256 _assets, bytes calldata _data) external;
}