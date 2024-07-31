// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

abstract contract Batch {
    function batchExecute(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            bool success;
            (success, results[i]) = address(this).delegatecall(data[i]);
            require(success, "Multicall failed");
        }
        return results;
    }
}