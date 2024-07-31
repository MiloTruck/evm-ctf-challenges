
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

contract Relayer {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
    
    struct Transaction {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        bytes data;
    }

    struct TransactionRequest {
        Transaction transaction;
        Signature signature;
    }

    uint256 public nonce;

    function execute(TransactionRequest calldata request) external payable {
        require(msg.value == request.transaction.value, "Insufficient value");
        
        bool success = _execute(request);
        require(success, "Execution failed");
    }

    function executeBatch(TransactionRequest[] calldata requests) external payable {
        bool success;
        uint256 totalValue;

        for (uint256 i = 0; i < requests.length; i++) {
            success = _execute(requests[i]);
            require(success, "Execution failed");

            totalValue += requests[i].transaction.value;
        }
        
        require(msg.value == totalValue, "Execution failed");
    }


    function _execute(TransactionRequest calldata request) internal returns (bool success) {
        Transaction memory transaction = request.transaction;
        Signature memory signature = request.signature;
        
        bytes32 transactionHash = keccak256(abi.encode(transaction, nonce++));
        address signer = ecrecover(transactionHash, signature.v, signature.r, signature.s);

        require(signer != address(0), "ecrecover failed");
        require(signer == transaction.from, "Wrong signer");
        require(block.timestamp <= signature.deadline, "Signature expired");

        uint256 g = transaction.gas;
        address a = transaction.to;
        uint256 v = transaction.value;
        bytes memory d = abi.encodePacked(transaction.data, transaction.from);

        uint256 gasLeft;
        assembly {
            success := call(g, a, v, add(d, 0x20), mload(d), 0, 0)
            gasLeft := gas()
        }

        require(gasLeft >= transaction.gas / 63, "Insufficient gas");
    }
}