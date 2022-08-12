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
    event DelegatorAdded(address delegator);
    event DelegatorRemoved(address delegator);
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

    /// @dev Adds a delegator to the registry. Initializes the delegator's stake with the provided amount.
    /// This function is only called by 'depositDelegatedStake'.
    /// @param _delegator The address of the delegator providing the stake.
    function addDelegator(address _delegator) internal {
        delegators[_delegator].addr = _delegator;

        // TODO: Figure out how to determine the numDelegators
        // numDelegators[block.number]++;

        emit DelegatorAdded(_delegator);
    }


    /// @dev Removes a delegator from the registry. This function is only called by 'withdrawDelegatedStake' when
    /// when a delegator chooses to withdraw the total amount of stake they have delegated.
    /// @param _delegator The address of the delegator.
    function removeDelegator(address _delegator) internal {
        delete delegators[_delegator];

        // TODO: Figure out how to determine the numDelegators
        // numDelegators[block.number]--;

        emit DelegatorRemoved(_delegator);
    }


    /// @dev Adds to the delegated stake of an existing delegator. This function is only called by 'depositDelegatedStake'.
    /// @param _delegator The address of the delegator.
    /// @param _validator The address of the validator to delegate stake to.
    /// @param _amount The amount of stake to delegate.
    function addStakeToDelegator(address _delegator, address _validator, uint256 _amount) internal {
        delegators[_delegator].delegatedValidators[_validator] += _amount;
        delegators[_delegator].totalDelegatedStake += _amount;

        addTotalDelegatedStaked(_amount);

        emit DelegatorIncreasedStake(_delegator, _validator, _amount);
    }


    /// @dev Subtracts to the delegated stake of an existing delegator. This function is only called by 'withdrawDelegatedStake'.
    /// @param _delegator The address of the delegator.
    /// @param _validator The address of the validator to subtract the delegated stake from.
    /// @param _amount The amount of delegated stake to remove.
    function subtractStakeFromDelegator(address _delegator, address _validator, uint256 _amount) internal {
        delegators[_delegator].delegatedValidators[_validator] -= _amount;
        delegators[_delegator].totalDelegatedStake -= _amount;

        substractTotalDelegatedStaked(_amount);

        emit DelegatorDecreasedStake(_delegator, _validator, _amount);
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
