// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./interfaces/IRegistry.sol";

contract Governance {

    // =============================================== Storage ========================================================

    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;

    /// @dev These state variables are initialized in the constructor but are dynamic given
    /// that more than a TBD amount of registered validators vote for a new
    /// value. These variables are placed here TEMPORARILY and will be moved to a governance
    /// contract where they can be voted upon.
    uint256 public voteQuorum; // The amount of votes needed to pass a proposal
    uint256 public voteTimePeriod; // The number of blocks a proposal is open for voting
    uint64 public slotSize; // The number of blocks included in each slot
    uint64 public epochSize; // The number of slots included in each epoch
    uint256 public penalty; // The percent of a validator's stake to be slashed
   
    IRegistry public Registry; // The address of the registry contract

    // ============================================== Constants =======================================================

    struct Proposal {
        uint256 id;
        uint256 timestamp;
        uint256 voteStartsAt;
        uint256 voteEndsAt;
        mapping(address => uint256) voters;
        uint256 votedStake;
        address proposer;
        ProposalStatus status;
        ProposalTopic topic;
        uint256 valueChange;
        address payable contractChange;
    }

    enum ProposalTopic { PENALTY, SLOT_SIZE, EPOCH_SIZE, VOTE_QUORUM, REGISTRY }

    enum ProposalStatus { CLOSED, OPEN, PASSED, FAILED, CANCELLED }

    // =============================================== Events ========================================================

    event ProposalCreated(
         uint256 id,
         uint256 timestamp,
         uint256 voteStartsAt,
         uint256 voteEndsAt,
         address proposer, 
         ProposalStatus status,
         ProposalTopic topic, 
         uint256 votedStake,
         uint256 valueChange,
         address payable contractChange
         );

    // =============================================== Getters ========================================================

    function isProposalOpen(uint256 _id) public view returns (bool) {
        return proposals[_id].status == ProposalStatus.OPEN && proposals[_id].voteEndsAt > block.number;
    }

    function isProposalPassed(uint256 _id) public view returns (bool) {
        return proposals[_id].status == ProposalStatus.PASSED;
    }

    function isProposalFailed(uint256 _id) public view returns (bool) {
        return proposals[_id].status == ProposalStatus.FAILED;
    }

    function isProposalExpired(uint256 _id) public view returns (bool) {
        return block.number >= proposals[_id].voteEndsAt;
    }

    function hasValidatorVoted(address _voter, uint256 _id) public view returns (bool) {
        return proposals[_id].voters[_voter] > 0;
    }

    // =============================================== Setters ========================================================

    /// @dev Initializes votable variables when contract is deployed.
    /// NOTE: These variables will be transferred to a governance contract when one is created.
    constructor(address _registry) {
        // Because Solidity only allows for integer division, we use a int
        // that is 0 < x <= 100,000 to represent a decimal with three decimal places.
        voteQuorum = 66666; // 66.666% penalty threshold
        voteTimePeriod = 100; // 100 blocks

        slotSize = 10; // 10 blocks per slot
        epochSize = 10; // 10 slots per epoch

        penalty = 2000; // 2.000% penalty enforced

        Registry = IRegistry(_registry); // The address of the registry contract
    }

    function cancelProposal(uint256 _id) public {
        require(Registry.isValidator(msg.sender), "Registered validators can only vote on proposals...");
        require(msg.sender == proposals[_id].proposer, "Only the proposer can cancel a proposal...");
        require(isProposalOpen(_id), "Proposal must be open to be cancelled...");

        proposals[_id].status = ProposalStatus.CANCELLED;
    }

    function finalizeProposal(uint256 _id) private {
        if ((proposals[_id].votedStake * 100000) / Registry.totalStaked() >= voteQuorum) {
            proposals[_id].status = ProposalStatus.PASSED;
        } else if (isProposalExpired(_id)) {
            proposals[_id].status = ProposalStatus.FAILED;
        } 
    }

    function voteOnProposal(uint256 _id) public {
        require(Registry.isValidator(msg.sender), "Registered validators can only vote on proposals...");
        require(isProposalOpen(_id), "Proposal is not available for voting anymore...");
        require(hasValidatorVoted(msg.sender, _id), "Validators can only vote once for a proposal...");
        
        if (!isProposalExpired(_id)) {
            uint256 stake = Registry.getStakeByAddress(msg.sender);
            proposals[_id].votedStake += stake;
        }
        finalizeProposal(_id);
    }


    function createProposal(ProposalTopic _reason, uint256 _change) public {
        // TODO: Should validators be the only people who can create proposals?
        require(Registry.isValidator(msg.sender), "Registered validators can only create proposals...");
        
        if (_reason == ProposalTopic.PENALTY) require(0 < _change && _change <= 100000, "Penalty must be 0 < PENALTY <= 100,000"); 
        else if (_reason == ProposalTopic.SLOT_SIZE) require(_change > 0, "Slot sizes must be greater than zero...");
        else if (_reason == ProposalTopic.EPOCH_SIZE) require(_change > 0, "Epoch sizes must be greater than zero...");
        else if (_reason == ProposalTopic.VOTE_QUORUM) require(0 < _change && _change <= 100000, "Voting quorum must be 0 < VOTING QUORUM <= 100,000"); 
        else if (_reason == ProposalTopic.REGISTRY) revert("Registry address must be a valid contract address...");
        else revert("Invalid proposal type. Proposal types must be 0 <= PROPOSAL TYPE <= 4...");

        numProposals++;

        proposals[numProposals].id = numProposals;
        proposals[numProposals].voteStartsAt = block.number;
        proposals[numProposals].voteEndsAt = block.number + voteTimePeriod;
        proposals[numProposals].timestamp = block.timestamp;
        proposals[numProposals].proposer = msg.sender;
        proposals[numProposals].topic = _reason;
        proposals[numProposals].status = ProposalStatus.OPEN;
        proposals[numProposals].valueChange = _change;
    }

    function createProposal(ProposalTopic _type, address payable _change) public {
        // TODO: Add functionality to report a registered validator
        require(Registry.isValidator(msg.sender), "Registered validators can only create proposals...");

        if (_type != ProposalTopic.REGISTRY) revert("Proposal value change must be of type uint256...");

        numProposals++;

        proposals[numProposals].id = numProposals;
        proposals[numProposals].voteStartsAt = block.number;
        proposals[numProposals].voteEndsAt = block.number + voteTimePeriod;
        proposals[numProposals].timestamp = block.timestamp;
        proposals[numProposals].proposer = msg.sender;
        proposals[numProposals].topic = _type;
        proposals[numProposals].status = ProposalStatus.OPEN;
        proposals[numProposals].contractChange = _change;
    }
}