// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IEscrowFactory {
    function ownerOf(uint256) external view returns (address);
}