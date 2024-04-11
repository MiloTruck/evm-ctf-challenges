// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { IERC20 } from "./lib/IERC20.sol";
import { History } from "./History.sol";

/// @title VotingVault
/// @notice The VotingVault contract.
contract VotingVault {
    using History for History.CheckpointHistory;

    struct Deposit {
        uint256 cumulativeAmount;
        uint256 unlockTimestamp;
    }

    struct UserData {
        Deposit[] deposits;
        uint256 front;
        address delegatee;
    }
    
    uint256 public constant VOTE_MULTIPLIER = 1.3e18;
    uint256 public constant LOCK_DURATION = 30 days;

    IERC20 public immutable GREY;

    History.CheckpointHistory internal history;

    mapping(address => UserData) public userData;

    /**
     * @param grey  The GREY token contract.
     */
    constructor(address grey) {
        GREY = IERC20(grey);
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Allows users to stake and lock GREY for votes.
     *
     * @param amount  The amount of GREY the user wishes to stake.
     * @return        Index of the deposit in the deposits array.
     */
    function lock(uint256 amount) external returns (uint256) {
        (UserData storage data, address delegatee) = _getUserData(msg.sender);
        Deposit[] storage deposits = data.deposits;

        if (deposits.length == 0) {
            deposits.push(Deposit(0, 0));
        }

        uint256 previousAmount = deposits[deposits.length - 1].cumulativeAmount;
        deposits.push(Deposit({
            cumulativeAmount: previousAmount + amount,
            unlockTimestamp: block.timestamp + LOCK_DURATION
        }));

        uint256 votes = _calculateVotes(amount);
        _addVotingPower(delegatee, votes);

        GREY.transferFrom(msg.sender, address(this), amount);

        return deposits.length - 1;
    }

    /**
     * @notice Withdraws staked GREY that is unlocked.
     *
     * @param end      The index of the last deposit to unlock.
     * @return amount  The amount of GREY unlocked.
     */
    function unlock(uint256 end) external returns (uint256 amount) {
        (UserData storage data, address delegatee) = _getUserData(msg.sender);
        Deposit[] storage deposits = data.deposits;
        
        uint256 front = data.front;
        require(front < end, "already unlocked");

        Deposit memory lastUnlockedDeposit = deposits[front];
        Deposit memory depositToUnlock = deposits[end];
        require(block.timestamp > depositToUnlock.unlockTimestamp, "still locked");
        
        amount = depositToUnlock.cumulativeAmount - lastUnlockedDeposit.cumulativeAmount;
        data.front = end;

        uint256 votes = _calculateVotes(amount);
        _subtractVotingPower(delegatee, votes);

        GREY.transfer(msg.sender, amount);
    }

    /**
     * @notice Transfer voting power from one address to another.
     *
     * @param newDelegatee  The new address which gets voting power.
     */
    function delegate(address newDelegatee) external {
        require(newDelegatee != address(0), "cannot delegate to zero address");

        (UserData storage data, address delegatee) = _getUserData(msg.sender);
        Deposit[] storage deposits = data.deposits;

        data.delegatee = newDelegatee;

        uint256 length = deposits.length;
        if (length == 0) return;

        Deposit storage lastUnlockedDeposit = deposits[data.front];
        Deposit storage lastDeposit = deposits[length - 1];
        uint256 amount = lastDeposit.cumulativeAmount - lastUnlockedDeposit.cumulativeAmount;
        
        uint256 votes = _calculateVotes(amount);
        _subtractVotingPower(delegatee, votes);
        _addVotingPower(newDelegatee, votes);
    }

    // ============================================ VIEW FUNCTIONS ===========================================

    /**
     * @notice Fetch the voting power of a user.
     *
     * @param user         The address we want to load the voting power from.
     * @param blockNumber  The block number we want the user's voting power at.
     *
     * @return             The number of votes.
     */
    function votingPower(address user, uint256 blockNumber) external view returns (uint256) {
        return history.getVotingPower(user, blockNumber);
    }

    // ============================================== HELPERS ===============================================
    
    function _addVotingPower(address delegatee, uint256 votes) internal {
        uint256 oldVotes = history.getLatestVotingPower(delegatee);
        unchecked { 
            history.push(delegatee, oldVotes + votes); 
        }
    }

    function _subtractVotingPower(address delegatee, uint256 votes) internal {
        uint256 oldVotes = history.getLatestVotingPower(delegatee);
        unchecked { 
            history.push(delegatee, oldVotes - votes); 
        }
    }

    function _calculateVotes(uint256 amount) internal pure returns (uint256) {
        return amount * VOTE_MULTIPLIER / 1e18;
    }

    function _getUserData(
        address user
    ) internal view returns (UserData storage data, address delegatee) {
        data = userData[user];
        delegatee = data.delegatee == address(0) ? user : data.delegatee;
    }
}