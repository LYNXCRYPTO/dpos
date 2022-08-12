// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./Validation.sol";
import "./Delegation.sol";

/// @dev Lets nodes register to become validator by depositing a stake or delegate a stake
/// to an existing valiadator. This contract is responsible for facilitating Lynx's consensus
/// mechanism as nodes can identify others as registered validators for purposes such as
/// voting for block proposals.
contract Registry is Validation, Delegation {


    // =============================================== Storage ========================================================

    /// @dev The total amount of stake residing in the registry. Both the stake deposited by validators and the stake
    /// deposited by delegators are added together to determine this quantity.
    uint256 public totalBonded;

    // =============================================== Getters ========================================================

    /// @dev Returns the amount of stake delegated by the provided delegator to a specific validator in the 
    /// validator set.
    /// @param _delegator The address of the delegator.
    /// @param _validator The address of the validator.
    function getDelegatedStakeToValidatorByAddress(address _delegator, address _validator)
        public
        view
        returns (uint256)
    {
        require(isValidatorDelegated(_delegator, _validator), "Delegator is not currently delegated to the provided validator...");

        return delegators[_delegator].delegatedValidators[_validator];
    }


    /// @dev Returns a boolean flag indicating whether the provided delegator is currently delegated to the
    /// specified validator.
    /// @param _delegator The address of the delegator.
    /// @param _validator The address of the validator.
    function isValidatorDelegated(address _delegator, address _validator) public view returns (bool) {
        require(isValidator(_validator), "Provided validator isn't validating currently...");

        if (isDelegator(_delegator)) return delegators[_delegator].delegatedValidators[_validator] > 0;
        
        return false;
    }

    // =============================================== Setters ========================================================

    /// @dev Adds a specified amount to the total stake desposited by validators and delegators. This function is
    /// only called when depositing/withdraw stake to/from the registry.
    /// @param _amount The amount of stake to add to the total bonded amount.
    function addTotalBonded(uint256 _amount) private {
        // TODO: Make sure to require that msg.sender == Voting.delegationContractAddress
        totalBonded += _amount;
    }


    /// @dev Subtracts a specified amount to the total stake desposited by validators and delegators. This function is
    /// only called when depositing/withdraw stake to/from the registry.
    /// @param _amount The amount of stake to add to the total bonded amount.
    function subtractTotalBonded(uint256 _amount) private {
        // TODO: Make sure to require that msg.sender == Voting.delegationContractAddress
        totalBonded -= _amount;
    }


    /// @dev Deposits a stake into the registry. If stake is valid, the sender will be registered as a validator and will
    /// be able to be queried for other operations such as consensus voting.
    function depositStake() public payable {
        require(msg.value > 0, "Can't deposit zero value...");

        bool isValidating = isValidator(msg.sender);

        if (!isValidating) addValidator(msg.sender);

        addStakeToValidator(msg.sender, msg.value);
        addTotalBonded(msg.value);
    }


    /// @dev Withdraws stake from the registry and transfers it to the provided payable address. If the sender 
    /// withdraws all of their stake, they will be removed from the validator set.
    /// @param _to A payable address to withdraw the stake to.
    /// @param _amount The amount of stake to withdraw.
    function withdrawStake(address payable _to, uint256 _amount) public {
        require(isValidator(msg.sender), "Sender is not currently a validator...");
        require(_amount <= validators[msg.sender].stake, "Sender does not have a sufficient amount staked currently...");
        require(_amount > 0, "Can't withdraw zero value...");
        
        uint256 stake = getStakeByAddress(msg.sender);
        subtractStakeFromValidator(msg.sender, _amount);

        if (_amount == stake) removeValidator(msg.sender);

        subtractTotalBonded(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdraw failed...");
    }


    /// @dev Deposits a stake to be delegated to a registered validator. If the validator exists, the sender will
    /// be added to the delegator set.
    /// @param _validator The address of the registered validator to delegate stake to.
    function depositDelegatedStake(address _validator) public payable {
        require(isValidator(_validator), "Can't delegate stake because validator doesn't exist...");
        require(msg.value > 0, "Can't deposit zero value...");

        bool isDelegating = isValidatorDelegated(msg.sender, _validator);

        if (!isDelegating) {
            addDelegator(msg.sender);
            addDelegatorToValidator(_validator, msg.sender);
        } 

        addStakeToDelegator(msg.sender, _validator, msg.value);
        addDelegatedStakeToValidator(_validator, msg.value);
        addTotalBonded(msg.value);
    }


    /// @dev Withdraws stake delegated to a registered validator and transfers it to the provided payable address.
    /// If the sender withdraws their total delegated stake, then they will be removed from the delegator set.
    /// @param _to A payable address to withdraw the stake to.
    /// @param _validator The registered validator to withdraw their delegated stake from.
    /// @param _amount The amount of stake to withdraw.
    function withdrawDelegatedStake(address payable _to, address _validator, uint256 _amount) public {
        require(isDelegator(msg.sender), "Sender is not currently a delegator...");
        require(isValidator(_validator), "Can't withdraw delegated stake because validator is not currently validating...");
        require(isValidatorDelegated(msg.sender, _validator), "Can't withdraw delegated stake because sender is not currently delegating to the specified validator...");
        require(_amount > 0, "Can't withdraw zero value...");
        require(_amount <= getDelegatedStakeToValidatorByAddress(msg.sender, _validator), "Sender does not have a sufficient amount of stake delegated currently...");
        
        uint256 delegatedStake = delegators[msg.sender].totalDelegatedStake;
        subtractStakeFromDelegator(msg.sender, _validator, _amount);

        if (_amount == delegatedStake) {
            removeDelegator(msg.sender);
            removeDelegatorFromValidator(_validator, msg.sender);
        } 

        subtractDelegatedStakeFromValidator(_validator, _amount);
        subtractTotalBonded(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdraw failed...");
    }
}
