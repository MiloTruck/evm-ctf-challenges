// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { IERC20 } from "./lib/IERC20.sol";
import { History } from "./History.sol";

contract VotingVault {
    using History for History.UserHistory;

    struct UserData {
        uint256 lockedAmount;
        uint256 votes;
        uint256 unlockTimestamp;
        address delegatee;
    }
    
    uint256 public constant ZERO_BONUS = 1.1e18;
    uint256 public constant SHORT_BONUS = 1.3e18;
    uint256 public constant LONG_BONUS = 1.5e18;

    uint256 public constant SHORT_DURATION = 30 days;
    uint256 public constant LONG_DURATION = 60 days;

    IERC20 public immutable GREY;

    History.UserHistory internal history;

    mapping(address => UserData) public userData;

    /**
     * @param grey  The GREY token contract.
     */
    constructor(address grey) {
        GREY = IERC20(grey);
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Allows users to stake and lock GREY for a boost in voting power.
     *
     * @param amount  The amount of GREY the user wishes to stake.
     * @param duration  The duration to lock GREY for.
     */
    function lock(uint256 amount, uint256 duration) external {
        (UserData memory data, address delegatee) = _getDelegatee(msg.sender);

        uint256 voteAmount = amount * _getBonus(duration) / 1e18;
        _addVotingPower(delegatee, voteAmount);

        data.lockedAmount += amount;
        data.votes += voteAmount;
        data.unlockTimestamp += duration;

        userData[msg.sender] = data;

        GREY.transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Withdraws staked tokens that are unlocked.
     */
    function unlock() external {
        (UserData memory data, address delegatee) = _getDelegatee(msg.sender);
        require(
            data.unlockTimestamp != 0 && block.timestamp > data.unlockTimestamp, 
            "not locked or lock still active"
        );

        _subtractVotingPower(delegatee, data.votes);

        delete userData[msg.sender];

        GREY.transfer(msg.sender, data.lockedAmount);
    }

    /**
     * @notice Transfer voting power from one address to another.
     *
     * @param newDelegatee  The new address which gets voting power.
     */
    function delegate(address newDelegatee) external {
        (UserData memory data, address delegatee) = _getDelegatee(msg.sender);

        _subtractVotingPower(delegatee, data.votes);
        _addVotingPower(newDelegatee, data.votes);

        userData[msg.sender].delegatee = newDelegatee;
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
    
    function _getBonus(uint256 duration) internal pure returns (uint256) {
        if (duration >= LONG_DURATION) return LONG_BONUS;
        if (duration >= SHORT_DURATION) return SHORT_BONUS;
        return ZERO_BONUS;
    }

    function _getDelegatee(
        address user
    ) internal view returns (UserData memory data, address delegatee) {
        data = userData[user];
        delegatee = data.delegatee == address(0) ? user : data.delegatee;
    }

    function _subtractVotingPower(address delegatee, uint256 votes) internal {
        uint256 oldVotes = history.getLatestVotingPower(delegatee);
        history.push(delegatee, oldVotes - votes);  
    }

    function _addVotingPower(address delegatee, uint256 votes) internal {
        uint256 oldVotes = history.getLatestVotingPower(delegatee);
        history.push(delegatee, oldVotes + votes);  
    }
}
