// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { ISafe } from "./interfaces/ISafe.sol";

contract Safe is ISafe {
    uint256 public constant OWNER_COUNT = 3;

    uint256 public constant VETO_DURATION = 1 minutes;

    address[OWNER_COUNT] public owners;

    mapping(bytes32 => uint256) internal queueHashToTimestamp;

    mapping(bytes32 => bool) internal transactionExecuted;

    constructor(address[OWNER_COUNT] memory _owners) {
        _setupOwners(_owners);
    }

    // ======================================= MODIFIERS ======================================

    modifier onlySelf() {
        if (msg.sender != address(this)) revert NotAuthorized();
        _;
    }

    modifier onlyOwner() {
        if (!isOwner(msg.sender)) revert NotAuthorized();
        _;
    }

    // ======================================= PERMISSIONED FUNCTIONS ======================================

    /**
     * @notice Replaces a current owner with a new owner.
     *
     * @param ownerIndex  The index of the owner to replace.
     * @param newOwner    The new owner address.  
     */
    function replaceOwner(uint256 ownerIndex, address newOwner) external onlySelf {
        if (ownerIndex >= OWNER_COUNT) revert InvalidIndex();
        if (newOwner == address(0)) revert OwnerCannotBeZeroAddress();
        
        for (uint256 i = 0; i < OWNER_COUNT; i++) {
            if (owners[i] == newOwner) {
                revert DuplicateOwner();
            }
        }

        owners[ownerIndex] = newOwner;
    }

    /**
     * @notice Allow owners to veto a queued transaction.
     *
     * @param queueHash  The hash of the queued transaction.
     */
    function vetoTransaction(bytes32 queueHash) external onlyOwner {
        uint256 queueTimestamp = queueHashToTimestamp[queueHash];
        if (queueTimestamp == 0) revert TransactionNotQueued();
        if (block.timestamp >= queueTimestamp + VETO_DURATION) revert NotInVetoPeriod();
        
        delete queueHashToTimestamp[queueHash];
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Allow users to queue transactions.
     *
     * @param v            The v value of signatures from all owners.
     * @param r            The r value of signatures from all owners.
     * @param s            The s value of signatures from all owners.
     * @param transaction  The transaction to execute.  
     * @return queueHash   The hash of the queued transaction.
     */
    function queueTransaction(
        uint8[OWNER_COUNT] calldata v,
        bytes32[OWNER_COUNT] calldata r,
        bytes32[OWNER_COUNT] calldata s,
        Transaction calldata transaction
    ) external returns (bytes32 queueHash) {
        if (!isOwner(transaction.signer)) revert SignerIsNotOwner();

        queueHash = keccak256(abi.encode(
            transaction,
            v,
            r,
            s
        ));

        queueHashToTimestamp[queueHash] = block.timestamp;
    }

    /**
     * @notice Execute a queued transaction.
     *
     * @param v               The v value of signatures from all owners.
     * @param r               The r value of signatures from all owners.
     * @param s               The s value of signatures from all owners.
     * @param transaction     The transaction to execute.  
     * @param signatureIndex  The index of the signature to use. 
     * @return success        Whether the executed transaction succeeded.
     * @return returndata     Return data from the executed transaction.
     */
    function executeTransaction(
        uint8[OWNER_COUNT] calldata v,
        bytes32[OWNER_COUNT] calldata r,
        bytes32[OWNER_COUNT] calldata s,
        Transaction calldata transaction,
        uint256 signatureIndex
    ) external payable returns (bool success, bytes memory returndata) {
        if (signatureIndex >= OWNER_COUNT) revert InvalidIndex();
        
        bytes32 queueHash = keccak256(abi.encode(
            transaction,
            v,
            r,
            s
        ));

        uint256 queueTimestamp = queueHashToTimestamp[queueHash];
        if (queueTimestamp == 0) revert TransactionNotQueued();
        if (block.timestamp < queueTimestamp + VETO_DURATION) revert StillInVetoPeriod();

        bytes32 txHash = keccak256(abi.encode(transaction));
        if (transactionExecuted[txHash]) revert TransactionAlreadyExecuted();

        address signer = ecrecover(
            txHash, 
            v[signatureIndex], 
            r[signatureIndex], 
            s[signatureIndex]
        );
        if (signer != transaction.signer) revert InvalidSignature();

        transactionExecuted[txHash] = true;
        (success, returndata) = transaction.to.call{ value: transaction.value }(transaction.data);
    }

    // ========================================= VIEW FUNCTIONS ========================================

    /**
     * @notice Check is an address is an owner.
     *
     * @param owner  The address to check for.
     * @return       Whether the address is an owner.
     */
    function isOwner(address owner) public view returns (bool) {
        for (uint256 i = 0; i < OWNER_COUNT; i++) {
            if (owner == owners[i]) {
                return true;
            }
        }
        return false;
    }

    // ========================================= HELPERS ========================================

    /**
     * @notice Initialize owners for the safe.
     *
     * @param newOwners  The addresses of all owners.
     */
    function _setupOwners(address[OWNER_COUNT] memory newOwners) internal {
        for (uint256 i = 0; i < OWNER_COUNT; i++) {
            if (newOwners[i] == address(0)) revert OwnerCannotBeZeroAddress();
            owners[i] = newOwners[i];
        }
    }

    receive() external payable {}
}