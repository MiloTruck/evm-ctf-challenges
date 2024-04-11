// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

library History {
    struct Checkpoint {
        uint32 blockNumber;
        uint224 votes;
    }

    struct CheckpointHistory {
        mapping(address => Checkpoint[]) checkpoints;
    }

    /**
     * @dev Pushes a (block.number, votes) checkpoint into a user's history.
     */
    function push(
        CheckpointHistory storage history,
        address user,
        uint256 votes
    ) internal {
        Checkpoint[] storage checkpoints = history.checkpoints[user];
        uint256 length = checkpoints.length;

        uint256 latestBlock;
        if (length != 0) {
            latestBlock = checkpoints[length - 1].blockNumber;
        }

        if (latestBlock == block.number) {
            checkpoints[length - 1].votes = uint224(votes);
        } else {
            checkpoints.push(Checkpoint({
                blockNumber: uint32(block.number),
                votes: uint224(votes)
            }));
        }
    }

    /**
     * @dev Returns votes in the last checkpoint, or zero if there is none.
     */
    function getLatestVotingPower(
        CheckpointHistory storage history,
        address user
    ) internal view returns (uint256) {
        Checkpoint[] storage checkpoints = history.checkpoints[user];
        uint256 length = checkpoints.length;

        return length == 0 ? 0 : checkpoints[length - 1].votes;
    }

    /**
     * @dev Returns votes in the last checkpoint with blockNumber lower or equal to 
     * latestBlock, or zero if there is none.
     */
    function getVotingPower(
        CheckpointHistory storage history,
        address user,
        uint256 latestBlock
    ) internal view returns (uint256) {
        Checkpoint[] storage checkpoints = history.checkpoints[user];

        uint256 low = 0;
        uint256 high = checkpoints.length;
        
        while (low < high) {
            uint256 mid = (high + low) / 2;
            if (checkpoints[mid].blockNumber > latestBlock) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : checkpoints[high - 1].votes;
    }
}