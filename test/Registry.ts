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

    describe("depositValidator()", function () {

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

        it("Should revert due to zero value being deposited", async function () {
            const { registry, validator } = await loadFixture(deployRegistry);

            const deposit = registry.connect(validator).depositStake({ value: ZERO_ETHER });

            await expect(deposit).to.be.revertedWith("Can't deposit zero value...");
        });
    });

    describe("withdrawValidator()", function () {

        it("Should withdraw validator's stake to validator's account", async function () {
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

            const address = await (await registry.validators(validator.address)).addr;
            expect(address).to.equal(ZERO_ADDRESS);
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

    });
});