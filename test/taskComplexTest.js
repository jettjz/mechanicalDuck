'use strict';

/* Add the dependencies you're testing */
const taskStandard = artifacts.require("./taskStandard.sol");
const Token = artifacts.require("./Queue.sol");
const taskThirdParty = artifacts.require("./taskThirdParty.sol");
// YOUR CODE HERE
// var Web3 = require('web3');
// var web3 = new Web3();
// web3.setProvider(new web3.providers.HttpProvider("http://localhost:8545"));

contract('taskThirdPartyTest', function(accounts) {
	/* Define your constant variables and instantiate constantly changing
	 * ones
	 */
	const args = {_zero: 0};
	let task;
	// YOUR CODE HERE
	let owner;
	let ipfs_test_submission;
	let ipfs_test_request;
	let verifiers;
	/* Do something before every `describe` method */
	beforeEach(async function() {
		owner = accounts[0];
		ipfs_test_request = "QmeZQ7CFTCxucyGxQJBhqxhU4Bb7aDL543HyqCqo53BiaR";
		ipfs_test_submission = "QmfB4w2Sqtc6wM2bLQeRAn8Zgd2LQEhheUnqSjqEwoivat";
		verifiers = [accounts[1], accounts[2], accounts[3]];
		task = await taskThirdParty.new("ez", 30, 5, 0, verifiers,  {from:  owner, value: 5});
	});

	/* Group test cases together
	 * Make sure to provide descriptive strings for method arguements and
	 * assert statements
	 */
	describe('--Instantiation: Basic--', function() {
		// it("The newly instantiated task should have a maxReward of 5000", async function() {
		// 	let maxReward = await task.maxReward.call();
		// 	assert.equal(maxReward, 5000, "task starts with 5000 wei");
		// });

		it("The end time should be 30 minutes after the start time", async function() {
			let start_time = await task.start_time.call();
			let end_time = await task.end_time.call();
			assert.equal(end_time - start_time, (30*60), "The start and end times are correct");
			let requester = await task.requester.call();
			assert.equal(requester, accounts[0], "The requester should be the creator of the contract");
		});
		it("The early_bird_end_time should be 0 minutes after the start time", async function() {
			let start_time = await task.start_time.call();
			let early_end_time = await task.early_bird_time.call();

			assert.equal(Number(start_time.valueOf()), Number(early_end_time.valueOf()), "The early_bird_time is correct");
		});
		it("The end_max_reward_time should be 0 minutes after the end time", async function() {
			let end_time = await task.end_time.call();
			let end_max_reward_time = await task.end_max_reward_time.call();

			assert.equal(Number(end_time.valueOf()), Number(end_max_reward_time.valueOf()), "The end_max_reward_time is correct");
		});
		it("The task request should be the required request", async function() {
			let request = await task.getRequestHash();

			assert.equal(request.valueOf(), "ez", "The task request hash is correct");
		});

		it("The reward should be five", async function() {
			let reward = await task.maxReward.call();

			assert.equal(Number(reward.valueOf()), 5, "The reward should be constructed to 5");
		});

		it("The owner should be able to raise the reward", async function() {
			task.addReward({from: accounts[0], value: 5});
			let reward = await task.maxReward.call();

			assert.equal(Number(reward.valueOf()), 10, "The reward should be constructed to 10");
		});

		it("The verifiers should be able to see they are verifiers", async function() {
			let verifiers_b = await task.getVerifiers();
			let a = verifiers_b.valueOf()[0];
			let b = verifiers_b.valueOf()[1];
			let c = verifiers_b.valueOf()[2];
			assert.equal(a, verifiers[0], "Verifiers should be equal");
			assert.equal(b, verifiers[1], "Verifiers should be equal");
			assert.equal(c, verifiers[2], "Verifiers should be equal");
		});


	});

	describe('--Queueing, Submitting, Approving, Denying--', function() {
		it("A worker should be able to submit their ipfs hash to the queue", async function() {
			await task.submit("test_request", {from: accounts[1]});
			let qsize = await task.getQSize();
			assert.equal(qsize.valueOf(), 1, "Correct queue size of 1");
			await task.submit("DUMMY_HASH",{from: accounts[2]});
			let qsize2 = await task.getQSize();
			let firstWorker = await task.getFirstAddress();
			let firstSubmission = await task.getFirstSubmission();
			assert.equal(firstSubmission.valueOf(), "test_request", "Correct first submission");
			assert.equal(qsize2.valueOf(), 2, "Correct queue size of 2");
			assert.equal(firstSubmission.valueOf(), "test_request", "Correct first submission");
		});
		it("The verifiers should be able to deny a buyer", async function() {
			await task.submit("test_request", {from: accounts[4]});
			await task.submit("part 2", {from: accounts[3]});
			await task.vote(false,{from: accounts[1]});
			await task.vote(false, {from: accounts[2]});
			let qsize = await task.getQSize();
			let firstAddress_a = await task.getFirstAddress();
			await task.checkVotes();
			let firstAddress_b = await task.getFirstAddress();
			assert.equal(qsize.valueOf(), 1, "Correct q size after denial");
			assert.equal(firstAddress_a.valueOf(), accounts[4], "Correct first submission");
			assert.equal(firstAddress_b.valueOf(), accounts[3], "Correct next submission")
		});
		it("The verifiers should be able to accept a buyer", async function() {
			await task.submit(ipfs_test_submission, {from: accounts[4]});
			await task.submit("DUMMY_HASH",{from: accounts[2]});
			await task.vote(true,{from: accounts[1]});
			await task.vote(true, {from: accounts[3]});
			let qsize = await task.getQSize();
			let firstAddress_a = await task.getFirstAddress();
			await task.checkVotes();
			let completed = await task.completed.call();
			let balance = await task.getBalance({from: accounts[1]});
			assert.equal(balance.valueOf(), 5, "Correct balance");
			assert.equal(completed.valueOf(), true, "Correct completed value");
		});
	});

});
