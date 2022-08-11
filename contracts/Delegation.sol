// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

contract Delegation {
    // Structure representing a delegator and their attributes
    struct Delegator {
        address addr;
        uint256 totalDelegatedStake;
        mapping(address => uint256) delegatedValidators; // Mapping of validator's address to delegated stake amount
    }

    // ***************
    // Accounting Variables
    // ***************
    uint256 public totalStakeDelegated;
    // TODO: Add/Subtract numDelegators when delegators are added/removed from set of delegators
    mapping(uint256 => uint256) public numDelegators; // Mapping of block number to number of delegators at that time
    mapping(address => Delegator) public delegators;

    // ***************
    // Delegator Events
    // ***************
    event DelegatorAdded(address delegator, address validator, uint256 stake);
    event DelegatorIncreasedStake(
        address delegator,
        address validator,
        uint256 stake
    );
    event DelegatorDecreasedStake(
        address delegator,
        address validator,
        uint256 stake
    );
    event DelegatorRemoved(address delegator, uint256 stake);
    event DelegatorPenalized(address delegator, uint256 penalty);

    // ***************
    // Constructor
    // ***************
    constructor() {
        // TODO: Add valdidation contract address to constructor (Voting.validationContractAddress).
        // NOTE: You can probably get rid of this constructor and disregard the previous line
        // validation = Validation(address(0));
    }

    // ***************
    // Getter Functions
    // ***************
    function isDelegator(address _delegator) public view returns (bool) {
        return
            delegators[_delegator].addr != address(0) && delegators[_delegator].totalDelegatedStake > 0;
    }

    // ***************
    // Helper Functions
    // ***************
    function addTotalDelegatedStaked(uint256 _amount) internal {
        totalStakeDelegated += _amount;
    }

    function substractTotalDelegatedStaked(uint256 _amount) internal {
        totalStakeDelegated -= _amount;
    }

    function getTotalDelegatedStakeOf(address _delegator)
        public
        view
        returns (uint256)
    {
        require(
            isDelegator(_delegator),
            "Provided delegator is not currently validating..."
        );
        return delegators[_delegator].totalDelegatedStake;
    }
}
