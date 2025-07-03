// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "./lib/IERC20.sol";
import {IERC721} from "./lib/IERC721.sol";
import {SafeERC20} from "./lib/SafeERC20.sol";

/// @title Locker
/// @notice Locks ERC20 tokens and ERC721 NFTs until a specified unlock time.
contract Locker {
    using SafeERC20 for IERC20;

    struct LockedToken {
        address token;
        uint256 amount;
        uint256 unlockTime;
        address creator;
        address receiver;
    }

    struct LockedNFT {
        address token;
        uint256 id;
        uint256 unlockTime;
        address creator;
        address receiver;
        bool unlocked;
    }

    uint256 public nextLockId = 1;

    mapping(uint256 => LockedToken) public lockedTokens;
    mapping(uint256 => LockedNFT) public lockedNFTs;

    // ======================================== ERC-20 FUNCTIONS ========================================

    /// @notice Lock ERC20 tokens.
    /// @param token ERC20 token address.
    /// @param amount Amount to lock.
    /// @param lockDuration Duration in seconds.
    /// @param receiver Address that can unlock later.
    function lockToken(address token, uint256 amount, uint256 lockDuration, address receiver)
        external
        returns (uint256 lockId)
    {
        lockId = nextLockId++;
        lockedTokens[lockId] = LockedToken({
            token: token,
            amount: amount,
            unlockTime: block.timestamp + lockDuration,
            creator: msg.sender,
            receiver: receiver
        });

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Extend unlock time of a token lock.
    /// @param lockId Lock identifier.
    /// @param newUnlockTime New unlock timestamp.
    function extendTokenLock(uint256 lockId, uint256 newUnlockTime) external {
        LockedToken storage lock = lockedTokens[lockId];

        require(msg.sender == lock.creator, "NOT_CREATOR");
        require(block.timestamp < lock.unlockTime, "ALREADY_UNLOCKED");
        require(newUnlockTime > lock.unlockTime, "TOO_EARLY");

        lock.unlockTime = newUnlockTime;
    }

    /// @notice Unlock ERC20 tokens when unlock time passed.
    /// @param lockId Lock identifier.
    function unlockToken(uint256 lockId, uint256 amount) external {
        LockedToken storage lock = lockedTokens[lockId];

        require(msg.sender == lock.receiver, "NOT_RECEIVER");
        require(block.timestamp >= lock.unlockTime, "NOT_UNLOCKED");

        lock.amount -= amount;

        IERC20(lock.token).safeTransferFrom(address(this), msg.sender, amount);
    }

    // ======================================== ERC-721 FUNCTIONS ========================================

    /// @notice Lock an ERC721 NFT.
    /// @param token NFT contract address.
    /// @param id Token id.
    /// @param lockDuration Duration in seconds.
    /// @param receiver Address that can unlock later.
    function lockNFT(address token, uint256 id, uint256 lockDuration, address receiver)
        external
        returns (uint256 lockId)
    {
        lockId = nextLockId++;
        lockedNFTs[lockId] = LockedNFT({
            token: token,
            id: id,
            unlockTime: block.timestamp + lockDuration,
            creator: msg.sender,
            receiver: receiver,
            unlocked: false
        });

        IERC721(token).transferFrom(msg.sender, address(this), id);
    }

    /// @notice Extend unlock time of an NFT lock.
    /// @param lockId Lock identifier.
    /// @param newUnlockTime New unlock timestamp.
    function extendNFTLock(uint256 lockId, uint256 newUnlockTime) external {
        LockedNFT storage lock = lockedNFTs[lockId];

        require(msg.sender == lock.creator, "NOT_CREATOR");
        require(block.timestamp < lock.unlockTime, "ALREADY_UNLOCKED");
        require(newUnlockTime > lock.unlockTime, "TOO_EARLY");

        lock.unlockTime = newUnlockTime;
    }

    /// @notice Unlock a locked NFT when unlock time passed.
    /// @param lockId Lock identifier.
    function unlockNFT(uint256 lockId) external {
        LockedNFT storage lock = lockedNFTs[lockId];

        require(msg.sender == lock.receiver, "NOT_RECEIVER");
        require(block.timestamp >= lock.unlockTime, "NOT_UNLOCKED");
        require(!lock.unlocked, "ALREADY_UNLOCKED");

        lock.unlocked = true;

        IERC721(lock.token).transferFrom(address(this), msg.sender, lock.id);
    }
}
