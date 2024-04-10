// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { IERC20 } from "../IERC20.sol";
import { History } from "./History.sol";

contract GWIFVault {
    using History for History.UserHistory;

    struct UserData {
        uint256 lockedAmount;
        uint256 votes;
        uint256 unlockTimestamp;
        address delegatee;
    }
    
    uint256 public constant SHORT_BONUS = 1.5e18;
    uint256 public constant LONG_BONUS = 2e18;

    uint256 public constant SHORT_DURATION = 30 days;
    uint256 public constant LONG_DURATION = 60 days;

    IERC20 public immutable GWIF;

    History.UserHistory internal history;

    mapping(address => UserData) public userData;

    /**
     * @param gwif  The GWIF token contract.
     */
    constructor(address gwif) {
        GWIF = IERC20(gwif);
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Allows users to stake and lock GWIF for a boost in voting power.
     *
     * @param amount  The amount GWIF the user wishes to stake.
     * @param duration  The duration to lock GWIF for.
     */
    function lock(uint256 amount, uint256 duration) external {
        require(amount != 0, "amount cannot be 0");
        
        UserData memory data = userData[msg.sender];
        require(data.lockedAmount == 0, "lock still active");

        uint256 voteAmount = amount * _getBonus(duration) / 1e18;
        history.push(msg.sender, voteAmount);

        userData[msg.sender] = UserData({
            lockedAmount: amount,
            votes: voteAmount,
            unlockTimestamp: block.timestamp + duration,
            delegatee: msg.sender
        });

        GWIF.transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Withdraws staked tokens that are unlocked.
     */
    function unlock() external {
        UserData memory data = userData[msg.sender];
        require(data.lockedAmount != 0, "lock not active");
        require(block.timestamp > data.unlockTimestamp, "still locked");

        uint256 oldVotes = history.getLatestVotingPower(data.delegatee);
        history.push(data.delegatee, oldVotes - data.votes);

        delete userData[msg.sender];

        GWIF.transfer(msg.sender, data.lockedAmount);
    }

    /**
     * @notice Transfer voting power from one address to another.
     *
     * @param newDelegatee  The new address which gets voting power.
     */
    function delegate(address newDelegatee) external {
        UserData memory data = userData[msg.sender];
        require(data.lockedAmount != 0, "lock not active");

        uint256 oldDelegateeVotes = history.getLatestVotingPower(data.delegatee);
        history.push(data.delegatee, oldDelegateeVotes - data.votes);

        uint256 newDelegateeVotes = history.getLatestVotingPower(newDelegatee);
        history.push(newDelegatee, newDelegateeVotes + data.votes);

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
        return 0;
    }
}
