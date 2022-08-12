import { expect } from "chai";
import hre from "hardhat";
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";

// Constants
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const ZERO_ETHER = hre.ethers.utils.parseEther("0");
const HALF_ETHER = hre.ethers.utils.parseEther("0.5");
const ONE_ETHER = hre.ethers.utils.parseEther("1");
const TWO_ETHER = hre.ethers.utils.parseEther("2");
const TX_GAS = 50000000000 // 50 Gwei

describe("Registry Contract", function () {

    async function deployRegistry() {
        const [owner, validator, delegator] = await hre.ethers.getSigners();
        const Registry = await hre.ethers.getContractFactory("Registry");
        const registry = await Registry.deploy();
        return { owner, validator, delegator, registry };
    }

    // Validation Tests Functions
    describe("Validation", function () {

        // depositStake() Tests
        describe("depositStake()", function () {

            it("Should add new validator to validator set", async function () {
                const { registry, validator } = await loadFixture(deployRegistry);

                await registry.connect(validator).depositStake({ value: ONE_ETHER });

                const address = await (await registry.validators(validator.address)).addr;

                expect(address).to.equal(validator.address);
            });

            it("Should increase existing validator's stake within validator set", async function () {
                const { registry, validator } = await loadFixture(deployRegistry);

                await registry.connect(validator).depositStake({ value: ONE_ETHER });
                await registry.connect(validator).depositStake({ value: ONE_ETHER });

                const stake = await (await registry.validators(validator.address)).stake;

                expect(stake).to.equal(TWO_ETHER);
            });

            it("Should revert due to deposit being of zero value", async function () {
                const { registry, validator } = await loadFixture(deployRegistry);

                const deposit = registry.connect(validator).depositStake({ value: ZERO_ETHER });

                await expect(deposit).to.be.revertedWith("Can't deposit zero value...");
            });
        });

        // withdrawStake() Tests
        describe("withdrawStake()", function () {

            it("Should withdraw validator's stake to specified account", async function () {
                const { registry, validator } = await loadFixture(deployRegistry);

                const beginningBalance = await validator.getBalance();

                const depositTX = await registry.connect(validator).depositStake({ value: ONE_ETHER });
                const depositReceipt = await depositTX.wait();
                const depositGasCost = depositReceipt.gasUsed.mul(depositReceipt.effectiveGasPrice);

                const withdrawTX = await registry.connect(validator).withdrawStake(validator.address, HALF_ETHER);
                const withdrawReceipt = await withdrawTX.wait();
                const withdrawGasCost = withdrawReceipt.gasUsed.mul(withdrawReceipt.effectiveGasPrice);

                const totalGasCost = depositGasCost.add(withdrawGasCost);

                const stake = await (await registry.validators(validator.address)).stake;
                expect(stake).to.equal(HALF_ETHER);

                const finalBalance = await validator.getBalance();
                expect(finalBalance).to.equal(beginningBalance.sub(HALF_ETHER).sub(totalGasCost));
            });

            it("Should remove validator from validator set", async function () {
                // TODO: Check to see if delegator/delegator's stake was removed from delegator set
                // Must also change in the .sol file

                const { registry, validator } = await loadFixture(deployRegistry);

                const beginningBalance = await validator.getBalance();

                const depositTX = await registry.connect(validator).depositStake({ value: ONE_ETHER });
                const depositReceipt = await depositTX.wait();
                const depositGasCost = depositReceipt.gasUsed.mul(depositReceipt.effectiveGasPrice);

                const withdrawTX = await registry.connect(validator).withdrawStake(validator.address, ONE_ETHER);
                const withdrawReceipt = await withdrawTX.wait();
                const withdrawGasCost = withdrawReceipt.gasUsed.mul(withdrawReceipt.effectiveGasPrice);

                const totalGasCost = depositGasCost.add(withdrawGasCost);

                const finalBalance = await validator.getBalance();
                expect(finalBalance).to.equal(beginningBalance.sub(totalGasCost));

                const validatorInfo = await registry.validators(validator.address)
                expect(await validatorInfo.addr).to.equal(ZERO_ADDRESS);
                expect(await validatorInfo.stake).to.equal(ZERO_ETHER);
            });

            it("Should revert due to validator not being staked", async function () {
                const { registry, validator } = await loadFixture(deployRegistry);

                const withdraw = registry.connect(validator).withdrawStake(validator.address, ZERO_ETHER);

                await expect(withdraw).to.be.revertedWith("Sender is not currently a validator...");
            });

            it("Should revert due to validator attempting to overwithdraw stake", async function () {
                const { registry, validator } = await loadFixture(deployRegistry);

                await registry.connect(validator).depositStake({ value: ONE_ETHER });
                const withdraw = registry.connect(validator).withdrawStake(validator.address, TWO_ETHER);

                await expect(withdraw).to.be.revertedWith("Sender does not have a sufficient amount staked currently...");
            });

            it("Should revert due to withdraw being of zero value", async function () {
                const { registry, validator } = await loadFixture(deployRegistry);

                await registry.connect(validator).depositStake({ value: ONE_ETHER });
                const withdraw = registry.connect(validator).withdrawStake(validator.address, ZERO_ETHER);

                await expect(withdraw).to.be.revertedWith("Can't withdraw zero value...");
            });
            // TODO: Add withdrawal failed test
        });
    });

    // Delegation Tests Functions
    describe("Delegation", function () {

        // depositDelegator() Tests
        describe("depositDelegatedStake()", function () {

            it("Should add new delegator to delegator set", async function () {
                const { registry, validator, delegator } = await loadFixture(deployRegistry);

                // Deposit stake to register validator
                await registry.connect(validator).depositStake({ value: ONE_ETHER });

                // Deposit stake to be delegated to validator
                await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });

                expect(await registry.isDelegator(delegator.address)).to.be.true;

                const delegatorInfo = await registry.delegators(delegator.address);
                expect(await delegatorInfo.addr).to.equal(delegator.address);
                expect(await delegatorInfo.totalDelegatedStake).to.equal(ONE_ETHER);

                const validatorInfo = await registry.validators(validator.address);
                expect(await validatorInfo.delegatedStake).to.equal(ONE_ETHER);

                expect(await registry.totalStakeDelegated()).to.equal(ONE_ETHER);
            });

            it("Should increase existing delegators's stake to a validator which they are already delegated to", async function () {
                // TODO: Check to see if validator is within's delegator's list of validators
                // in which the are delegated to
                const { registry, validator, delegator } = await loadFixture(deployRegistry);

                // Deposit stake to register validator
                await registry.connect(validator).depositStake({ value: ONE_ETHER });

                // Deposit stake to be delegated to validator
                await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });
                await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });

                const delegatorInfo = await registry.delegators(delegator.address);
                expect(await delegatorInfo.addr).to.equal(delegator.address);
                expect(await delegatorInfo.totalDelegatedStake).to.equal(TWO_ETHER);

                const validatorInfo = await registry.validators(validator.address);
                expect(await validatorInfo.delegatedStake).to.equal(TWO_ETHER);

                expect(await registry.totalStakeDelegated()).to.equal(TWO_ETHER);
            });

            it("Should increase existing delegator's stake when delegated to a new validator", async function () {
                // TODO: Check to see if validator is within's delegator's list of validators
                // in which the are delegated to
                const { registry, owner, validator, delegator } = await loadFixture(deployRegistry);

                // Deposit stake to register two validators
                await registry.connect(validator).depositStake({ value: ONE_ETHER });
                await registry.connect(owner).depositStake({ value: ONE_ETHER });

                // Deposit stake to be delegated to validator
                await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });
                await registry.connect(delegator).depositDelegatedStake(owner.address, { value: ONE_ETHER });

                const delegatorInfo = await registry.delegators(delegator.address);
                expect(await delegatorInfo.totalDelegatedStake).to.equal(TWO_ETHER);

                const validatorInfo = await registry.validators(validator.address);
                expect(await validatorInfo.delegatedStake).to.equal(ONE_ETHER);

                const otherValidatorInfo = await registry.validators(owner.address);
                expect(await otherValidatorInfo.delegatedStake).to.equal(ONE_ETHER);

                expect(await registry.totalStakeDelegated()).to.equal(TWO_ETHER);
            });

            it("Should revert due to validator not being staked", async function () {
                const { registry, owner, validator, delegator } = await loadFixture(deployRegistry);

                // Deposit stake to be delegated to validator
                const deposit = registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });

                await expect(deposit).to.be.revertedWith("Can't delegate stake because validator doesn't exist...");
            });

            it("Should revert due to withdraw being of zero value", async function () {
                const { registry, owner, validator, delegator } = await loadFixture(deployRegistry);

                // Deposit stake to register two validators
                await registry.connect(validator).depositStake({ value: ONE_ETHER });

                // Deposit stake to be delegated to validator
                const deposit = registry.connect(delegator).depositDelegatedStake(validator.address, { value: ZERO_ETHER });

                await expect(deposit).to.be.revertedWith("Can't deposit zero value...");
            });
        });

        describe("withdrawDelegatedStake()", function () {

            it("Should withdraw delegator's stake to specified account", async function () {
                const { registry, validator, delegator } = await loadFixture(deployRegistry);

                const beginningBalance = await delegator.getBalance();

                // Deposit validator stake and add to validator set
                await registry.connect(validator).depositStake({ value: ONE_ETHER });

                // Delegate stake to registered validator
                const depositTX = await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });
                const depositReceipt = await depositTX.wait();
                const depositGasCost = depositReceipt.gasUsed.mul(depositReceipt.effectiveGasPrice);

                // Withdraw delegated stake to delegator's account
                const withdrawTX = await registry.connect(delegator).withdrawDelegatedStake(delegator.address, validator.address, HALF_ETHER);
                const withdrawReceipt = await withdrawTX.wait();
                const withdrawGasCost = withdrawReceipt.gasUsed.mul(withdrawReceipt.effectiveGasPrice);

                const totalGasCost = depositGasCost.add(withdrawGasCost);

                const finalBalance = await delegator.getBalance();
                expect(finalBalance).to.equal(beginningBalance.sub(HALF_ETHER).sub(totalGasCost));

                const delegatorInfo = await registry.delegators(delegator.address);
                expect(await delegatorInfo.totalDelegatedStake).to.equal(HALF_ETHER);

                const validatorInfo = await registry.validators(validator.address);
                expect(await validatorInfo.delegatedStake).to.equal(HALF_ETHER);

                expect(await registry.totalStakeDelegated()).to.equal(HALF_ETHER);
                expect(await registry.totalBonded()).to.equal(ONE_ETHER.add(HALF_ETHER));
            });

            it("Should remove delegator from delegator set", async function () {
                const { registry, validator, delegator } = await loadFixture(deployRegistry);

                const beginningBalance = await delegator.getBalance();

                // Deposit validator stake and add to validator set
                await registry.connect(validator).depositStake({ value: ONE_ETHER });

                // Delegate stake to registered validator
                const depositTX = await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });
                const depositReceipt = await depositTX.wait();
                const depositGasCost = depositReceipt.gasUsed.mul(depositReceipt.effectiveGasPrice);

                // Withdraw delegated stake to delegator's account
                const withdrawTX = await registry.connect(delegator).withdrawDelegatedStake(delegator.address, validator.address, ONE_ETHER);
                const withdrawReceipt = await withdrawTX.wait();
                const withdrawGasCost = withdrawReceipt.gasUsed.mul(withdrawReceipt.effectiveGasPrice);

                const totalGasCost = depositGasCost.add(withdrawGasCost);

                const finalBalance = await delegator.getBalance();
                expect(finalBalance).to.equal(beginningBalance.sub(totalGasCost));

                const delegatorInfo = await registry.delegators(delegator.address);
                expect(await delegatorInfo.totalDelegatedStake).to.equal(ZERO_ETHER);
                expect(await delegatorInfo.addr).to.equal(ZERO_ADDRESS);

                const validatorInfo = await registry.validators(validator.address);
                expect(await validatorInfo.delegatedStake).to.equal(ZERO_ETHER);

                expect(await registry.totalStakeDelegated()).to.equal(ZERO_ETHER);
                expect(await registry.totalBonded()).to.equal(ONE_ETHER);
            });

            it("Should revert due to delegator not having any stake delegated", async function () {
                const { registry, validator, delegator } = await loadFixture(deployRegistry);

                // Withdraw delegated stake to delegator's account
                const withdraw = registry.connect(delegator).withdrawDelegatedStake(delegator.address, validator.address, ONE_ETHER);

                await expect(withdraw).to.be.revertedWith("Sender is not currently a delegator...");
            });

            it("Should revert due to validator not being staked", async function () {
                const { registry, owner, validator, delegator } = await loadFixture(deployRegistry);

                // Deposit validator stake and add to validator set
                await registry.connect(validator).depositStake({ value: ONE_ETHER });

                // Delegate stake to registered validator
                await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });

                // Withdraw delegated stake to delegator's account
                const withdraw = registry.connect(delegator).withdrawDelegatedStake(delegator.address, owner.address, ONE_ETHER);

                await expect(withdraw).to.be.revertedWith("Can't withdraw delegated stake because validator is not currently validating...");
            });

            it("Should revert due to delegator not having any stake delegated to the specified validator", async function () {
                const { registry, owner, validator, delegator } = await loadFixture(deployRegistry);

                // Deposit validator stake and add to validator set
                await registry.connect(validator).depositStake({ value: ONE_ETHER });
                await registry.connect(owner).depositStake({ value: ONE_ETHER });

                // Delegate stake to registered validator
                await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });

                // Withdraw delegated stake to delegator's account
                const withdraw = registry.connect(delegator).withdrawDelegatedStake(delegator.address, owner.address, ONE_ETHER);

                await expect(withdraw).to.be.revertedWith("Can't withdraw delegated stake because sender is not currently delegating to the specified validator...");
            });

            it("Should revert due to withdraw being of zero value", async function () {
                const { registry, owner, validator, delegator } = await loadFixture(deployRegistry);

                // Deposit validator stake and add to validator set
                await registry.connect(validator).depositStake({ value: ONE_ETHER });

                // Delegate stake to registered validator
                await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });

                // Withdraw delegated stake to delegator's account
                const withdraw = registry.connect(delegator).withdrawDelegatedStake(delegator.address, validator.address, ZERO_ETHER);

                await expect(withdraw).to.be.revertedWith("Can't withdraw zero value...");
            });

            it("Should revert due to delegator attempting to overwithdraw stake to the specified delegator", async function () {
                const { registry, owner, validator, delegator } = await loadFixture(deployRegistry);

                // Deposit validator stake and add to validator set
                await registry.connect(validator).depositStake({ value: ONE_ETHER });

                // Delegate stake to registered validator
                await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });

                // Withdraw delegated stake to delegator's account
                const withdraw = registry.connect(delegator).withdrawDelegatedStake(delegator.address, validator.address, TWO_ETHER);

                await expect(withdraw).to.be.revertedWith("Sender does not have a sufficient amount of stake delegated currently...");
            });
        });

        // getDelegatedStakeToValidatorByAddress() Tests
        describe("getDelegatedStakeToValidatorByAddress()", function () {
            it("Should return the amount of stake delegated to a validator by a specified delegator", async function () {
                const { registry, validator, delegator } = await loadFixture(deployRegistry);

                await registry.connect(validator).depositStake({ value: ONE_ETHER });
                await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });

                const delegatedStake = await registry.getDelegatedStakeToValidatorByAddress(delegator.address, validator.address);

                expect(delegatedStake).to.equal(ONE_ETHER);
            });

            it("Should revert due to the provided delegator not having any stake delegated", async function () {
                const { registry, validator, delegator } = await loadFixture(deployRegistry);

                await registry.connect(validator).depositStake({ value: ONE_ETHER });

                const delegatedStake = registry.getDelegatedStakeToValidatorByAddress(delegator.address, validator.address);

                await expect(delegatedStake).to.be.revertedWith("Provided delegator is not currently delegating...");
            });

            it("Should revert due to the provided validator not having any stake", async function () {
                const { registry, validator, delegator } = await loadFixture(deployRegistry);

                await registry.connect(validator).depositStake({ value: ONE_ETHER });
                await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });

                const delegatedStake = registry.getDelegatedStakeToValidatorByAddress(delegator.address, ZERO_ADDRESS);

                await expect(delegatedStake).to.be.revertedWith("Provided validator is not currently validating...");
            });

            it("Should revert due to the provided delegator not delegated any stake to the specified validator", async function () {
                const { registry, owner, validator, delegator } = await loadFixture(deployRegistry);

                await registry.connect(validator).depositStake({ value: ONE_ETHER });
                await registry.connect(owner).depositStake({ value: ONE_ETHER });

                await registry.connect(delegator).depositDelegatedStake(validator.address, { value: ONE_ETHER });

                const delegatedStake = registry.getDelegatedStakeToValidatorByAddress(delegator.address, owner.address);

                await expect(delegatedStake).to.be.revertedWith("Delegator is not currently delegated to the provided validator...");
            });
        });
    });
});