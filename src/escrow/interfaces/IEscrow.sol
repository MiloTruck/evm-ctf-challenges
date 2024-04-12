// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IEscrow {
    function escrowId() external view returns (uint256);

    function initialize() external;
}