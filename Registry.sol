// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "./Validation.sol";
import "./Delegation.sol";

contract Registry is Validation, Delegation {
    // ***************
    // Accounting Variables
    // ***************
    uint256 public totalBonded; // The total amount of lynx staked and delegated within the system

    // ***************
    // Getter Functions
    // ***************
    function getDelegatedStakeOf(address _delegator, address _validator)
        public
        view
        returns (uint256)
    {
        require(
            isDelegator(_delegator),
            "Provided delegator is not currently validating..."
        );
        require(
            isValidator(_validator),
            "Provided validator is not currently validating..."
        );
        require(
            isValidatorDelegated(_delegator, _validator),
            "Delegator is not currently delegated to the provided validator..."
        );
        return delegators[_delegator].delegatedValidators[_validator];
    }

    // ***************
    // Helper Functions
    // ***************
    function addTotalBondedStake(uint256 _amount) private {
        // TODO: Make sure to require that msg.sender == Voting.delegationContractAddress
        totalBonded += _amount;
    }

    function subtractTotalBondedStake(uint256 _amount) private {
        // TODO: Make sure to require that msg.sender == Voting.delegationContractAddress
        totalBonded -= _amount;
    }

    function isValidatorDelegated(address _delegator, address _validator)
        public
        view
        returns (bool)
    {
        require(
            isDelegator(_delegator),
            "Provided delegator isn't delegating currently..."
        );
        require(
            isValidator(_validator),
            "Provided delegator isn't delegating currently..."
        );
        return delegators[_delegator].delegatedValidators[_validator] > 0;
    }

    function delegateStake(
        address _delegator,
        address _validator,
        uint256 _amount
    ) private {
        require(
            isDelegator(_delegator),
            "Provided delegator isn't delgating currently..."
        );
        require(
            isValidator(_delegator),
            "Provided delegator isn't delgating currently..."
        );
        validators[_validator].delegators.push(_delegator);
        validators[_validator].delegatedStake += _amount;
        validators[_validator].totalStake += _amount;
    }

    function addDelegator(
        address _delegator,
        address _validator,
        uint256 _amount
    ) private {
        delegateStake(_delegator, _validator, _amount);

        delegators[_delegator].addr = _delegator;
        delegators[_delegator].totalDelegatedStake = _amount;
        delegators[_delegator].delegatedValidators[_validator] = _amount;

        addTotalDelegatedStaked(_amount);
        addTotalBondedStake(_amount);
        numDelegators[block.number + 1]++;

        emit DelegatorAdded(_delegator, _validator, _amount);
    }

    function removeDelegator(address _delegator, uint256 _amount) private {
        delete delegators[_delegator];
        substractTotalDelegatedStaked(_amount);
        subtractTotalBondedStake(_amount);
        numDelegators[block.number + 1]--;
        emit DelegatorRemoved(_delegator, _amount);
    }

    function addDelegatedStake(
        address _delegator,
        address _validator,
        uint256 _amount
    ) private {
        delegators[_delegator].delegatedValidators[_validator] += _amount;
        delegators[_delegator].totalDelegatedStake += _amount;

        delegateStake(_delegator, _validator, _amount);

        addTotalDelegatedStaked(_amount);
        addTotalBondedStake(_amount);

        emit DelegatorIncreasedStake(_delegator, _validator, _amount);
    }

    function subtractDelegatedStake(
        address _delegator,
        address _validator,
        uint256 _amount
    ) private {
        // TODO: Get rid of for loop and replace with constant time look up
        uint256 numOfDelegators = validators[_validator].delegators.length;
        for (uint64 i; i < numOfDelegators; i++) {
            if (_delegator == validators[_validator].delegators[i]) {
                validators[_validator].delegators[i] = validators[_validator]
                    .delegators[numOfDelegators - 1];
                validators[_validator].delegators.pop();
            }
        }

        validators[_validator].delegatedStake -= _amount;
        validators[_validator].totalStake -= _amount;

        delegators[_delegator].delegatedValidators[_validator] -= _amount;
        delegators[_delegator].totalDelegatedStake -= _amount;

        substractTotalDelegatedStaked(_amount);
        subtractTotalBondedStake(_amount);

        emit DelegatorDecreasedStake(_delegator, _validator, _amount);
    }

    // ***************
    // Payable Validator Functions
    // ***************
    function depositStake() public payable {
        bool isValidating = isValidator(msg.sender);

        if (isValidating) {
            addStake(msg.sender, msg.value);
        } else {
            addValidator(msg.sender, msg.value);
        }
    }

    function withdrawStake(address _to, uint256 _amount) public payable {
        require(
            isValidator(msg.sender),
            "Sender is not currently a validator..."
        );
        require(
            _amount > validators[msg.sender].stake,
            "Sender does not have a sufficient amount staked currently..."
        );
        require(payable(_to).send(0), "To address is not payable...");

        uint256 stake = validators[msg.sender].stake;
        if (_amount < stake) {
            subtractStake(msg.sender, _amount);
        } else {
            removeValidator(msg.sender, stake);
        }

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdraw failed...");
    }

    // ***************
    // Payable Delegator Functions
    // ***************
    function depositDelegatedStake(address _validator, uint256 _amount)
        public
        payable
    {
        require(
            isDelegator(_validator),
            "Can't delegate stake because validator doesn't exist..."
        );

        bool isDelegating = isValidatorDelegated(msg.sender, _validator);

        if (isDelegating) {
            addDelegatedStake(msg.sender, _validator, _amount);
        } else {
            addDelegator(msg.sender, _validator, _amount);
        }
    }

    function withdrawDelegatedStake(
        address _to,
        address _validator,
        uint256 _amount
    ) public payable {
        require(
            isDelegator(msg.sender),
            "Sender is not currently a delegator..."
        );
        require(
            isValidator(_validator),
            "Can't withdraw delegated stake becase validator is not currently validating..."
        );
        require(
            isValidatorDelegated(msg.sender, _validator),
            "Can't withdraw delegated stake because sender is not currently delegating to the specified validator..."
        );
        require(
            _amount > getStakeOf(msg.sender),
            "Sender does not have a sufficient amount of stake delegated currently..."
        );
        require(payable(_to).send(0), "To address is not payable...");

        uint256 delegatedStake = delegators[msg.sender].totalDelegatedStake;
        if (_amount < delegatedStake) {
            subtractDelegatedStake(msg.sender, _validator, _amount);
        } else {
            removeDelegator(msg.sender, delegatedStake);
            subtractTotalBondedStake(delegatedStake);
        }

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdraw failed...");
    }
}
