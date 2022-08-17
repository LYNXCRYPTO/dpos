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
enum ProposalTopic { PENALTY, SLOT_SIZE, EPOCH_SIZE, VOTE_QUORUM, REGISTRY }
enum ProposalStatus { CLOSED, OPEN, PASSED, FAILED, CANCELLED }


describe("Governance Contract", function () {

    async function deployRegistry() {
        const [owner, proposer, voter] = await hre.ethers.getSigners();
        const Registry = await hre.ethers.getContractFactory("Registry");
        const registry = await Registry.deploy();
        return { owner, proposer, voter, registry };
    }

    async function deployGovernance() {
        const { owner, proposer, voter, registry } = await loadFixture(deployRegistry);
        const block = await hre.ethers.provider.getBlock("latest");
        const Governance = await hre.ethers.getContractFactory("Governance");
        const governance = await Governance.deploy(registry.address);
        return { owner, proposer, voter, governance, registry, block };
    }

    describe("createProposal()", function () {

        describe("Value Change Proposal", function () {

            it("Should create a new proposal to change strictness of penalties", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = await governance.connect(proposer)["createProposal(uint8,uint256)"](ProposalTopic.PENALTY, 99999);

                const voteTimePeriod = await governance.voteTimePeriod();

                const blockNumber = await hre.ethers.provider.getBlockNumber();
                const block = await hre.ethers.provider.getBlock(blockNumber);

                expect(await governance.numProposals()).to.equal(1);

                const proposal = await governance.proposals(1);
                expect(proposal.id).to.equal(1);
                expect(proposal.timestamp).to.equal(block.timestamp);
                expect(proposal.voteStartsAt).to.equal(block.number);
                expect(proposal.voteEndsAt).to.equal(voteTimePeriod.add(block.number));
                expect(proposal.proposer).to.equal(proposer.address);
                expect(proposal.topic).to.equal(ProposalTopic.PENALTY);
                expect(proposal.status).to.equal(ProposalStatus.OPEN);
                expect(proposal.valueChange).to.equal(99999);
                expect(proposal.contractChange).to.equal(ZERO_ADDRESS);
            });

            it("Should create a new proposal to change the size of a slot", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = await governance.connect(proposer)["createProposal(uint8,uint256)"](ProposalTopic.SLOT_SIZE, 20);

                const voteTimePeriod = await governance.voteTimePeriod();

                const blockNumber = await hre.ethers.provider.getBlockNumber();
                const block = await hre.ethers.provider.getBlock(blockNumber);

                expect(await governance.numProposals()).to.equal(1);

                const proposal = await governance.proposals(1);
                expect(proposal.id).to.equal(1);
                expect(proposal.timestamp).to.equal(block.timestamp);
                expect(proposal.voteStartsAt).to.equal(block.number);
                expect(proposal.voteEndsAt).to.equal(voteTimePeriod.add(block.number));
                expect(proposal.proposer).to.equal(proposer.address);
                expect(proposal.topic).to.equal(ProposalTopic.SLOT_SIZE);
                expect(proposal.status).to.equal(ProposalStatus.OPEN);
                expect(proposal.valueChange).to.equal(20);
                expect(proposal.contractChange).to.equal(ZERO_ADDRESS);
            });

            it("Should create a new proposal to change the size of an epoch", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = await governance.connect(proposer)["createProposal(uint8,uint256)"](ProposalTopic.EPOCH_SIZE, 20);

                const voteTimePeriod = await governance.voteTimePeriod();

                const blockNumber = await hre.ethers.provider.getBlockNumber();
                const block = await hre.ethers.provider.getBlock(blockNumber);

                expect(await governance.numProposals()).to.equal(1);

                const proposal = await governance.proposals(1);
                expect(proposal.id).to.equal(1);
                expect(proposal.timestamp).to.equal(block.timestamp);
                expect(proposal.voteStartsAt).to.equal(block.number);
                expect(proposal.voteEndsAt).to.equal(voteTimePeriod.add(block.number));
                expect(proposal.proposer).to.equal(proposer.address);
                expect(proposal.topic).to.equal(ProposalTopic.EPOCH_SIZE);
                expect(proposal.status).to.equal(ProposalStatus.OPEN);
                expect(proposal.valueChange).to.equal(20);
                expect(proposal.contractChange).to.equal(ZERO_ADDRESS);
            });

            it("Should create a new proposal to change the quorum for all proposals to pass", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = await governance.connect(proposer)["createProposal(uint8,uint256)"](ProposalTopic.VOTE_QUORUM, 99999);

                const voteTimePeriod = await governance.voteTimePeriod();

                const blockNumber = await hre.ethers.provider.getBlockNumber();
                const block = await hre.ethers.provider.getBlock(blockNumber);

                expect(await governance.numProposals()).to.equal(1);

                const proposal = await governance.proposals(1);
                expect(proposal.id).to.equal(1);
                expect(proposal.timestamp).to.equal(block.timestamp);
                expect(proposal.voteStartsAt).to.equal(block.number);
                expect(proposal.voteEndsAt).to.equal(voteTimePeriod.add(block.number));
                expect(proposal.proposer).to.equal(proposer.address);
                expect(proposal.topic).to.equal(ProposalTopic.VOTE_QUORUM);
                expect(proposal.status).to.equal(ProposalStatus.OPEN);
                expect(proposal.valueChange).to.equal(99999);
                expect(proposal.contractChange).to.equal(ZERO_ADDRESS);
            });

            it("Should revert due to sender not being a registered validator", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = governance.connect(voter)["createProposal(uint8,uint256)"](ProposalTopic.PENALTY, 100);

                await expect(createProposal).to.be.revertedWith("Registered validators can only create proposals...");
            });

            it("Should revert due to penalty being out of range of valid values", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = governance.connect(proposer)["createProposal(uint8,uint256)"](ProposalTopic.PENALTY, 101000);

                await expect(createProposal).to.be.revertedWith("Penalty must be 0 < PENALTY <= 100,000");
            });

            it("Should revert due to slot size not being greater than zero", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = governance.connect(proposer)["createProposal(uint8,uint256)"](ProposalTopic.SLOT_SIZE, 0);

                await expect(createProposal).to.be.revertedWith("Slot sizes must be greater than zero...");
            });

            it("Should revert due to epoch size not being greater than zero", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = governance.connect(proposer)["createProposal(uint8,uint256)"](ProposalTopic.EPOCH_SIZE, 0);

                await expect(createProposal).to.be.revertedWith("Epoch sizes must be greater than zero...");
            });

            it("Should revert due to vote quorum being out of range of valid values", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = governance.connect(proposer)["createProposal(uint8,uint256)"](ProposalTopic.VOTE_QUORUM, 101000);

                await expect(createProposal).to.be.revertedWith("Voting quorum must be 0 < VOTING QUORUM <= 100,000");
            });

            it("Should revert due to number being provided instead of contract address", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = governance.connect(proposer)["createProposal(uint8,uint256)"](ProposalTopic.REGISTRY, 6969);

                await expect(createProposal).to.be.revertedWith("Registry address must be a valid contract address...");
            });
        });

        describe("Address Change Proposal", function () {

            it("Should create a new proposal to change the address of the registry contract", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = await governance.connect(proposer)["createProposal(uint8,address)"](ProposalTopic.REGISTRY, voter.address);

                const voteTimePeriod = await governance.voteTimePeriod();

                const blockNumber = await hre.ethers.provider.getBlockNumber();
                const block = await hre.ethers.provider.getBlock(blockNumber);

                expect(await governance.numProposals()).to.equal(1);

                const proposal = await governance.proposals(1);
                expect(proposal.id).to.equal(1);
                expect(proposal.timestamp).to.equal(block.timestamp);
                expect(proposal.voteStartsAt).to.equal(block.number);
                expect(proposal.voteEndsAt).to.equal(voteTimePeriod.add(block.number));
                expect(proposal.proposer).to.equal(proposer.address);
                expect(proposal.topic).to.equal(ProposalTopic.REGISTRY);
                expect(proposal.status).to.equal(ProposalStatus.OPEN);
                expect(proposal.valueChange).to.equal(0);
                expect(proposal.contractChange).to.equal(voter.address);


            });

            it("Should revert due to sender not being a registered validator (address)", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = governance.connect(voter)["createProposal(uint8,address)"](ProposalTopic.REGISTRY, ZERO_ADDRESS);

                await expect(createProposal).to.be.revertedWith("Registered validators can only create proposals...");
            });

            it("Should revert due to the proposal topic being anything other than REGISTRY", async function () {
                const { governance, proposer, voter, registry } = await loadFixture(deployGovernance);

                await registry.connect(proposer).depositStake({ value: ONE_ETHER });

                const createProposal = governance.connect(proposer)["createProposal(uint8,address)"](ProposalTopic.PENALTY, ZERO_ADDRESS);

                await expect(createProposal).to.be.revertedWith("Proposal value change must be of type uint256...");
            });
        });
    });
});