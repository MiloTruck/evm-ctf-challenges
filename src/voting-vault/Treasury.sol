// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { IERC20 } from "./lib/IERC20.sol";
import { VotingVault } from "./VotingVault.sol";

/// @title Treasury
/// @notice The Treasury contract.
contract Treasury {
    struct Proposal {
        bool executed;
        address recipient;
        address token;
        uint256 amount;
        uint256 votes;
    }
    
    VotingVault public immutable VAULT;

    uint256 public immutable minimumVotes;

    Proposal[] public proposals;

    mapping(uint256 => mapping(address => bool)) voted;

    mapping(address => uint256) public reserves;

    /**
     * @param _vault         The VotingVault contract.
     * @param _minimumVotes  Minimum number of votes required for a proposal to pass.
     */
    constructor(address _vault, uint256 _minimumVotes) {
        VAULT = VotingVault(_vault);
        minimumVotes = _minimumVotes;
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Deposit tokens into the tresury.
     *
     * @param token  The token to deposit.
     * @param amount  The amount of tokens to deposit.
     */
    function deposit(address token, uint256 amount) external {
        reserves[token] += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Create a proposal to withdraw tokens from the treasury.
     *
     * @param token      The token to withdraw.
     * @param amount     The amount of tokens to withdraw.
     * @param recipient  The address that receives the tokens.
     */
    function propose(address token, uint256 amount, address recipient) external returns (uint256) {
        require(amount <= reserves[token], "insufficient tokens");
        
        proposals.push(Proposal({
            executed: false,
            recipient: recipient,
            token: token,
            amount: amount,
            votes: 0
        }));

        return proposals.length - 1;
    }

    /**
     * @notice Vote for a withdrawal proposal.
     *
     * @param proposalId  The index of the proposal in the proposals array.
     */
    function vote(uint256 proposalId) external {
        require(!voted[proposalId][msg.sender], "already voted");
        voted[proposalId][msg.sender] = true;

        uint256 votingPower = VAULT.votingPower(msg.sender, block.number - 1);
        proposals[proposalId].votes += votingPower;
    }

    /**
     * @notice Execute a withdrawal proposal.
     *
     * @param proposalId  The index of the proposal in the proposals array.
     */
    function execute(uint256 proposalId) external {
        Proposal memory proposal = proposals[proposalId];
        require(!proposal.executed, "already executed");
        require(proposal.votes >= minimumVotes, "threshold not reached");

        proposals[proposalId].executed = true;
        reserves[proposal.token] -= proposal.amount;

        IERC20(proposal.token).transfer(proposal.recipient, proposal.amount);
    }
}