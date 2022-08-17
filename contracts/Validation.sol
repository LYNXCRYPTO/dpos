// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

contract Validation {

    // =============================================== Storage ========================================================

    /// @dev The total amount of stake deposited by registered validators currently.
    uint256 public totalStaked;

    /// @dev A mapping of a block's number to the number of registered validators at that time.
    /// TODO: Figure out how to add/subtract to this number when validators are added/removed from set of validators
    uint256 public numValidators;

    /// @dev A mapping of registered validator's address to their stored attributes.
    mapping(address => Validator) public validators;

    // ============================================== Constants =======================================================

    /// @dev Structure representing a validator and their attributes.
    struct Validator {
        address addr;
        uint256 stake;
        uint256 delegatedStake;
        uint256 totalStake;
        address[] delegators;
        mapping(address => uint256) delegatorPositions; // Mapping of delegator address to index within delegators array
    }

    // =============================================== Events ========================================================

    /// @dev Emitted by the 'addValidator' function to signal that a new validator has been registered and
    /// added to the validator set.
    /// @param validator The address of the validator that has been added.
    event ValidatorAdded(address validator);

    /// @dev Emitted by the 'removeValidator' function to signal that a registered validator has been
    /// removed from the validator set.
    /// @param validator The address of the validator that has been removed.
    event ValidatorRemoved(address validator);

    /// @dev Emitted by the 'addStakeToValidator' function to signal that a validator has deposited
    /// additional stake.
    /// @param validator The address of the validator that has deposited stake.
    /// @param amount The amount of stake that has been added.
    event ValidatorIncreasedStake(address validator, uint256 amount);

    /// @dev Emitted by the 'removeStakeFromValidator' function to signal that a validator has withdrew
    /// all or a portion of their stake.abi
    /// @param validator The address of the validator that has withdrawn stake.
    /// @param amount The amount of stake that has been removed.
    event ValidatorDecreasedStake(address validator, uint256 amount);

    // =============================================== Getters ========================================================

    /// @dev Returns the total amount of stake deposited by all registered validators currently.
    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }


    /// @dev Returns a boolean flag indicating whether a validator is registered and exists
    /// within the current validator set.
    /// @param _validator The address of the validator to check.
    function isValidator(address _validator) public view returns (bool) {
        return validators[_validator].addr != address(0) && validators[_validator].stake > 0;
    }


    /// @dev Returns the amount of stake a validator has deposited currently. The validator
    /// must be registered and exist within the current validator set.
    /// @param _validator The address of the validator to get the stake of.
    function getStakeByAddress(address _validator) public view returns (uint256) {
        require(isValidator(_validator), "Provided validator isn't validating currently...");
        return validators[_validator].stake;
    }

    // =============================================== Setters ========================================================

    /// @dev Adds a specified amount to the total stake deposited by validators. This function is
    /// only called when depositing stake to the registry.
    /// @param _amount The amount of stake to be added to the total stake amount.
    function addTotalStaked(uint256 _amount) private {
        totalStaked += _amount;
    }


    /// @dev Subtracts a specified amount to the total stake deposited by validators. This function is
    /// only called when withdrawing stake from the registry.
    /// @param _amount The amount of stake to be subtracted to the total stake amount.
    function substractTotalStaked(uint256 _amount) private {
        totalStaked -= _amount;
    }


    /// @dev Appends a delegator's address to a registered validator's array of delegators. Additionally,
    /// stores the index + 1 at which the address is stored within delegator array for easy retrieval
    /// later on. The index + 1 is stored because in Solidity, all uint256s are initialized to 0 which
    /// would conflict with the element at the zeroth index.
    /// @param _validator The address of the validator to add the delegator to.
    /// @param _delegator The address of the delegator to add to the validator's array of delegators.
    function addDelegatorToValidator(address _validator, address _delegator) internal {
        validators[_validator].delegators.push(_delegator);
        validators[_validator].delegatorPositions[_delegator] = validators[_validator].delegators.length;
    }


    /// @dev Removes a delegator's address from a registered validator's array of delegators. Additionally,
    /// removes the index at which the address is stored within delegator array.
    /// @param _validator The address of the validator to remove the delegator from.
    /// @param _delegator The address of the delegator to remove from the validator's array of delegators.
    function removeDelegatorFromValidator(address _validator, address _delegator) internal {
        uint256 numOfDelegators = validators[_validator].delegators.length;
        address lastDelegator = validators[_validator].delegators[numOfDelegators - 1];
        uint256 delegatorPosition = validators[_validator].delegatorPositions[_delegator];

        validators[_validator].delegators[delegatorPosition - 1] = lastDelegator;
        validators[_validator].delegators.pop();
        validators[_validator].delegatorPositions[lastDelegator] = delegatorPosition;
        validators[_validator].delegatorPositions[_delegator] = 0;
    }


    /// @dev Adds a specified amount to a validator's amount of stake delegated to them and
    /// their total amount of stake (validator's stake + amount of stake delegated to them).
    /// @param _validator The address of the validator to add the delegated stake to.
    /// @param _amount The amount of stake to be added to the validator's delegated stake and total stake.
    function addDelegatedStakeToValidator( address _validator, uint256 _amount) internal {
        validators[_validator].delegatedStake += _amount;
        validators[_validator].totalStake += _amount;
    }


    /// @dev Subtracts a specified amount from a validator's amount of stake delegated to them and
    /// their total amount of stake.
    /// @param _validator The address of the validator to subtract the delegated stake from.
    /// @param _amount The amount of stake to be subtracted from the validator's delegated stake and total stake.
    function subtractDelegatedStakeFromValidator(address _validator, uint256 _amount) internal {
        validators[_validator].delegatedStake -= _amount;
        validators[_validator].totalStake -= _amount;
    }

    
    /// @dev Registers a validator and adds them to the current set of validators.
    /// @param _validator The address of the validator to register.
    function addValidator(address _validator) internal {
        validators[_validator].addr = _validator;

        numValidators++;

        emit ValidatorAdded(_validator);
    }


    /// @dev Removes a validator from the current set of validators.
    /// @param _validator The address of the validator to remove from the validator set.
    function removeValidator(address _validator) internal {
        delete validators[_validator];

        numValidators--;

        emit ValidatorRemoved(_validator);
    }


    /// @dev Adds to the stake of an existing validator. This function is only called by the 
    /// 'depositStake' function within the Registry contract.
    /// @param _validator The address of the validator to increase the stake of.
    /// @param _amount The amount of stake to be added to the registered validator's profile.
    function addStakeToValidator(address _validator, uint256 _amount) internal {
        validators[_validator].stake += _amount;
        validators[_validator].totalStake += _amount;

        addTotalStaked(_amount);

        emit ValidatorIncreasedStake(_validator, _amount);
    }


    /// @dev Subtracts from the stake of an existing validator. This function is only called by the 
    /// 'withdrawStake' function within the Registry contract.
    /// @param _validator The address of the validator to decrease the stake of.
    /// @param _amount The amount of stake to be removed from the registered validator's profile.
    function subtractStakeFromValidator(address _validator, uint256 _amount) internal {
        validators[_validator].stake -= _amount;

        substractTotalStaked(_amount);

        emit ValidatorDecreasedStake(_validator, _amount);
    }
}
