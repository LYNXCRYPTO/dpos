// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

contract Validation {
    struct Allegation {
        mapping(address => uint256) witnesses; // Mapping of reporter's address to the timestamp of when they reported it
        uint256 numWitnesses;
        uint256 totalStakeOfWitnesses;
    }

    struct Validator {
        address addr;
        uint256 stake;
        uint256 delegatedStake;
        uint256 totalStake;
        address[] delegators;
        // TODO: Add mapping of delegator address to index within delegators array
        mapping(uint256 => Allegation) allegations; // Mapping of block number to any allegations
    }

    // ***************
    // Accounting variables
    // ***************
    uint256 public totalStaked;
    mapping(uint256 => uint256) public numValidators; // Mapping of block number to number of validators at that time
    mapping(address => Validator) public validators;

    // ***************
    // Votable variables
    // ***************
    uint256 public penaltyThreshold; // The amount of reports needed to penalize a validator
    uint256 public penalty; // The percent of a validator's stake to be slashed
    uint64 public decisionThreshold; // The number of consecutive successes required for a block to be finalized
    uint64 public slotSize; // The number of blocks included in each slot
    uint64 public epochSize; // The number of slots included in each epoch

    // ***************
    // Validator Events
    // ***************
    event ValidatorAdded(address validator, uint256 stake);
    event ValidatorIncreasedStake(address validator, uint256 stakeIncrease);
    event ValidatorDecreasedStake(address validator, uint256 stakeDecrease);
    event ValidatorRemoved(address validator, uint256 stake);
    event ValidatorReported(
        address reporter,
        address validator,
        uint256 blockNumber
    );
    event ValidatorPenalized(
        address validator,
        uint256 blockNumber,
        uint256 penalty
    );

    // ***************
    // Constructor
    // ***************
    constructor() {
        slotSize = 10; // 10 blocks per slot
        epochSize = 10; // 10 slots per epoch

        decisionThreshold = 20; // 20 consecutive successes required for a block to be finalized

        // Because Solidity only allows for integer division, we use a int
        // that is 0 < x <= 100,000 to represent a decimal with three decimal places.
        penaltyThreshold = 66666; // 66.666% penalty threshold
        penalty = 2000; // 2.000% penalty enforced
    }

    // ***************
    // Getter Functions
    // ***************
    function isValidator(address _validator) public view returns (bool) {
        return
            validators[_validator].addr != address(0) &&
            validators[_validator].stake > 0;
    }

    function getNumOfValidatorsByBlockNumber(uint256 _blockNumber)
        external
        view
        returns (uint256)
    {
        require(
            _blockNumber <= block.number,
            "Block has yet to be created yet..."
        );
        return numValidators[_blockNumber];
    }

    function getStakeByAddress(address _validator)
        public
        view
        returns (uint256)
    {
        require(
            isValidator(_validator),
            "Provided validator isn't validing currently..."
        );
        return validators[_validator].stake;
    }

    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }

    // ***************
    // Helper Functions
    // ***************
    function addTotalStaked(uint256 _amount) private {
        totalStaked += _amount;
    }

    function substractTotalStaked(uint256 _amount) private {
        totalStaked -= _amount;
    }

    function addValidator(address _validator, uint256 _amount) internal {
        validators[_validator].addr = _validator;
        validators[_validator].stake = _amount;
        validators[_validator].delegatedStake = 0;
        validators[_validator].totalStake = _amount;

        addTotalStaked(_amount);
        // TODO: Figure out how to determine the numValidators
        //numValidators[block.number]++;

        emit ValidatorAdded(_validator, _amount);
    }

    function addStake(address _validator, uint256 _amount) internal {
        validators[_validator].stake += _amount;
        addTotalStaked(_amount);
        emit ValidatorIncreasedStake(_validator, _amount);
    }

    function subtractStake(address _validator, uint256 _amount) internal {
        validators[_validator].stake -= _amount;
        substractTotalStaked(_amount);
        emit ValidatorDecreasedStake(_validator, _amount);
    }

    function removeValidator(address _validator, uint256 _amount) internal {
        delete validators[_validator];
        substractTotalStaked(_amount);
        //numValidators[block.number]--;
        emit ValidatorRemoved(_validator, _amount);
    }
}
