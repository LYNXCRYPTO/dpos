// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

interface IValidation {
    function isValidator(address _validator) external view returns (bool);

    function totalStaked() external view returns (uint256);

    function totalBonded() external view returns (uint256);

    function getNumOfValidators(uint256) external view returns (uint256);
}
