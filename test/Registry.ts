import { expect } from "chai";
import hre from "hardhat";
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";


describe("Registry Contract", function () {

    async function deployRegistry() {
        const [owner, otherAccount] = await hre.ethers.getSigners();
        const Registry = await hre.ethers.getContractFactory("Registry");
        const registry = await Registry.deploy();
        return { owner, otherAccount, registry };
    }

    // describe("Deployment", function () {
    //     it("Registry Contract should be deployed", async function () {
    //         const [owner, otherAccount] = await hre.ethers.getSigners();

    //         const Registry = await hre.ethers.getContractFactory("Registry");

    //         const registry = await Registry.deploy();

    //         console.log(await registry.address);

    //     });
    // });

    describe("Register Validator", function () {
        it("Validator should be registered", async function () {

            const { registry, otherAccount } = await loadFixture(deployRegistry);

            await registry.connect(otherAccount).depositStake({ value: hre.ethers.utils.parseEther("1") });

            console.log(await registry.getStakeByAddress(otherAccount.address));
        });
    });
});