// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {EnumerableSet} from "./lib/EnumerableSet.sol";
import {GREY} from "./lib/GREY.sol";

/// @title Race
/// @notice Simple racing game that pools GREY tokens and awards the pot when the race starts.
/// @dev Players must join before `startTime`; winner selection is not implemented for brevity.
contract Race {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RaceData {
        uint256 payout;
        uint256 startTime;
        uint256 entryPrice;
        EnumerableSet.AddressSet players;
    }

    GREY public immutable grey;

    uint256 public nextRaceId = 1;
    mapping(uint256 => RaceData) internal races;

    /// @param _grey Address of the GREY token contract.
    constructor(address _grey) {
        grey = GREY(_grey);
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /// @notice Create a new race.
    /// @param payout Initial pot contributed by the creator.
    /// @param duration Seconds until the race starts.
    /// @param entryPrice Fee required for each player to join.
    /// @return raceId The ID of the newly created race.
    function createRace(uint256 payout, uint256 duration, uint256 entryPrice) external returns (uint256 raceId) {
        raceId = nextRaceId++;
        RaceData storage race = races[raceId];

        race.payout = payout;
        race.startTime = block.timestamp + duration;
        race.entryPrice = entryPrice;

        grey.transferFrom(msg.sender, address(this), payout);
    }

    /// @notice Join a race before it starts.
    /// @param raceId The race to join.
    function enterRace(uint256 raceId) external {
        RaceData storage race = races[raceId];

        require(block.timestamp < race.startTime, "RACE_ENDED");
        require(!race.players.contains(msg.sender), "ALREADY_ENTERED");

        race.payout += race.entryPrice;
        race.players.add(msg.sender);

        grey.transferFrom(msg.sender, address(this), race.entryPrice);
    }

    /// @notice Claim the entire pot for a race after it has started.
    /// @param raceId The race to claim.
    function claimPayout(uint256 raceId) external {
        RaceData storage race = races[raceId];

        require(block.timestamp >= race.startTime, "RACE_NOT_STARTED");
        require(race.players.contains(msg.sender), "NOT_PLAYER");

        delete races[raceId].players;

        grey.transfer(msg.sender, race.payout);
    }

    // ========================================= VIEW FUNCTIONS ========================================

    /// @notice View data for a race.
    /// @param raceId The race to query.
    /// @return payout Current prize pool.
    /// @return startTime Block timestamp when the race starts.
    /// @return entryPrice Entry fee for new players.
    function getRace(uint256 raceId) external view returns (uint256, uint256, uint256) {
        RaceData storage race = races[raceId];

        return (race.payout, race.startTime, race.entryPrice);
    }
}
