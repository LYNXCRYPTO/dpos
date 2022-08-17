// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

contract Delegation {

    // =============================================== Storage ========================================================

    /// @dev The total amount of stake delegated by registered delegators curremtly.
    uint256 public totalStakeDelegated;

    /// @dev A mapping of a block's number to the number of registered delegators at that time.
    uint256 public numDelegators;

    /// @dev A mapping of registered delegator's address to their stored attributes.
    mapping(address => Delegator) public delegators;

    // ============================================== Constants =======================================================

    /// @dev Structure representing a delegator and their attributes.
    struct Delegator {
        address addr;
        uint256 totalDelegatedStake;
        mapping(address => uint256) delegatedValidators; // Mapping of validator's address to delegated stake amount
    }

    // =============================================== Events ========================================================

    /// @dev Emitted by the 'addDelegator' function to signal that a new delegator has been registered and
    /// added to the delegator set.
    /// @param delegator The address of the delegator that has been added.
    event DelegatorAdded(address delegator);

    /// @dev Emitted by the 'removeDelegator' function to signal that a registered delegator has been
    /// removed from the delegator set.
    /// @param delegator The address of the delegator that has been removed.
    event DelegatorRemoved(address delegator);

    /// @dev Emitted by the 'addStakeToDelegator' function to signal that a delegator has deposited
    /// stake to be delegated to a specified validator.
    /// @param delegator The address of the registered delegator that has deposited stake.
    /// @param validator The address of the registered validator that received the delegated stake.
    /// @param amount The amount of stake that has been delegated.
    event DelegatorIncreasedStake(address delegator, address validator, uint256 amount);

    /// @dev Emitted by the 'subtractStakeFromDelegator' function to signal that a delegator has withdrew
    /// delegated stake from a specified validator.
    /// @param delegator The address of the registered delegator that has withdrew stake.
    /// @param validator The address of the registered validator that the stake was delegated to.
    /// @param amount The amount of delegated stake that has been withdrawn.
    event DelegatorDecreasedStake(address delegator, address validator, uint256 amount);

    /// @dev This event are a part of the governance part of this protocol. IT will be moved to
    /// a governance contract when one is created.
    event DelegatorPenalized(address delegator, uint256 penalty);

    // =============================================== Getters ========================================================

    /// @dev Returns a boolean flag indicating whether the provided delegator is currently registered.
    /// @param _delegator The address of the delegator to check.
    function isDelegator(address _delegator) public view returns (bool) {
        return delegators[_delegator].addr != address(0) && delegators[_delegator].totalDelegatedStake > 0;
    }


    /// @dev Returns the total amount of stake delegated by the provided delegator.
    /// @param _delegator The address of the delegator to get the total delegated stake of.
    function getTotalDelegatedStakeOf(address _delegator) public view returns (uint256) {
        require(isDelegator(_delegator), "Provided delegator is not currently validating...");

        return delegators[_delegator].totalDelegatedStake;
    }

    // =============================================== Setters ========================================================

    /// @dev Adds a specified amount to the total stake delegated by all registered delegators currently. This function is
    /// only called when delegating stake to a registered validator.
    /// @param _amount The amount of delegated stake to be added to the total delegated stake amount.
    function addTotalDelegatedStaked(uint256 _amount) internal {
        totalStakeDelegated += _amount;
    }
    

    /// @dev Subtracts a specified amount from the total stake delegated by all registered delegators currently. This function is
    /// only called when withdrawing delegated stake from a registered validator.
    /// @param _amount The amount of delegated stake to be added to the total delegated stake amount.
    function substractTotalDelegatedStaked(uint256 _amount) internal {
        totalStakeDelegated -= _amount;
    }


    /// @dev Adds a delegator to the registry. Initializes the delegator's stake with the provided amount.
    /// This function is only called by 'depositDelegatedStake'.
    /// @param _delegator The address of the delegator providing the stake.
    function addDelegator(address _delegator) internal {
        delegators[_delegator].addr = _delegator;

        numDelegators++;

        emit DelegatorAdded(_delegator);
    }


    /// @dev Removes a delegator from the registry. This function is only called by 'withdrawDelegatedStake' when
    /// when a delegator chooses to withdraw the total amount of stake they have delegated.
    /// @param _delegator The address of the delegator.
    function removeDelegator(address _delegator) internal {
        delete delegators[_delegator];

        numDelegators--;

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
}
