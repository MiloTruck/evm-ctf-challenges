// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface ISafe {
    struct Transaction {
        address signer;
        address to;
        uint256 value;
        bytes data;
    }

    error DuplicateOwner();
    error InvalidIndex();
    error InvalidSignature();
    error NotAuthorized();
    error NotInVetoPeriod();
    error OwnerCannotBeZeroAddress();
    error SignerIsNotOwner();
    error StillInVetoPeriod();
    error TransactionAlreadyExecuted();
    error TransactionNotQueued();

    function OWNER_COUNT() external view returns (uint256);

    function VETO_DURATION() external view returns (uint256);

    function executeTransaction(
        uint8[3] memory v,
        bytes32[3] memory r,
        bytes32[3] memory s,
        Transaction memory transaction,
        uint256 signatureIndex
    ) external payable returns (bool success, bytes memory returndata);

    function isOwner(address owner) external view returns (bool);

    function owners(uint256) external view returns (address);

    function queueTransaction(
        uint8[3] memory v,
        bytes32[3] memory r,
        bytes32[3] memory s,
        Transaction memory transaction
    ) external returns (bytes32 queueHash);

    function replaceOwner(uint256 ownerIndex, address newOwner) external;

    function vetoTransaction(bytes32 queueHash) external;
}