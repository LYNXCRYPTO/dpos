// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IRegistry {
    function totalStaked() external returns (uint256);
    function totalDelegated() external returns (uint256);
    function totalBonded() external returns (uint256);
    function numValidators() external returns (uint256);
    function numDelegators() external returns (uint256);
    function isValidator(address _validator) external returns (bool);
    function getStakeByAddress(address _validator) external returns (uint256);
}