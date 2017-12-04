'use strict';

/* Add the dependencies you're testing */
const Queue = artifacts.require("./Queue.sol");

contract('queueTest', function(accounts) {
	/* Define your constant variables and instantiate constantly changing
	 * ones
	 */
	const args = {_zero: 0};
	let queue;
	let ipfs_test_submission;
	/* Do something before every `describe` method */
	beforeEach(async function() {
		// deploy new queue to use
		queue = await Queue.new(5);
		ipfs_test_submission = "QmfB4w2Sqtc6wM2bLQeRAn8Zgd2LQEhheUnqSjqEwoivat";
	});

	/* Group test cases together
	 * Make sure to provide descriptive strings for method arguements and
	 * assert statements
	 */
	describe('--Instantiation--', function() {
		it("The newly instantiated queue should be empty", async function() {
			let isEmpty = await queue.empty.call();
			assert.equal(isEmpty.valueOf(), true, "Newly instantiated queue is empty");

			let qsize = await queue.qsize.call();
			assert.equal(qsize.valueOf(), args._zero, "Newly instantiated queue spotsFilled is zero");
		});

	});

	describe('--Adding Users to Queue--', function() {
		it("Adding users", async function() {
			await queue.enqueue(accounts[0], "DUMMY_HASH");

			let qsize = await queue.qsize.call();
			assert.equal(qsize.valueOf(), 1, "User 1 added - spotsFilled is now 1");

			let isEmpty = await queue.empty.call();
			assert.equal(isEmpty.valueOf(), false, "Queue is no longer empty");

			let pos = await queue.checkPlace.call({from: accounts[0]});
			assert.equal(pos.valueOf(), 1, "User 1 is in position 1");

			let otherpos = await queue.checkPlace.call({from: accounts[1]});
			assert.equal(otherpos.valueOf(), 0, "Other user has no result for checkPosition");

			let first = await queue.getFirstAddress.call();
			assert.equal(first.valueOf(), accounts[0], "getFirst matches user 1");

			await queue.enqueue(accounts[1], ipfs_test_submission);

			qsize = await queue.qsize.call();
			assert.equal(qsize.valueOf(), 2, "User 2 added - spotsFilled is now 2");

			pos = await queue.checkPlace.call({from: accounts[1]});
			assert.equal(pos.valueOf(), 2, "User 2 is in position 2");

			await queue.enqueue(accounts[2], "DUMMY_HASH2");

			qsize = await queue.qsize.call();
			assert.equal(qsize.valueOf(), 3, "User 3 added - spotsFilled is now 3");

			pos = await queue.checkPlace.call({from: accounts[2]});
			assert.equal(pos.valueOf(), 3, "User is in position 3");

			await queue.enqueue(accounts[3], "DUMMY_HASH3");

			qsize = await queue.qsize.call();
			assert.equal(qsize.valueOf(), 4, "User 4 added - spotsFilled is now 4");

			pos = await queue.checkPlace.call({from: accounts[3]});
			assert.equal(pos.valueOf(), 4, "User is in position 4");

			await queue.enqueue(accounts[4], "DUMMY_HASH3");

			qsize = await queue.qsize.call();
			assert.equal(qsize.valueOf(), 5, "User 5 added - spotsFilled is now 5");

			pos = await queue.checkPlace.call({from: accounts[4]});
			assert.equal(pos.valueOf(), 5, "User 5 is in position 5");

			await queue.enqueue(accounts[5], "DUMMY_HASH3");

			qsize = await queue.qsize.call();
			assert.equal(qsize.valueOf(), 5, "Extra user doesn't change spotsFilled - still is 5");

			let isFull = await queue.isFull.call();
			assert.equal(isFull, true, "Newly instantiated queue is Full");

			pos = await queue.checkPlace.call({from: accounts[5]});
			assert.equal(pos.valueOf(), 0, "Extra user doesn't have position in queue");
		});
	});

	describe("--Removing users from queue--", async function() {
		it("Removing from an empty queue", async function() {
			await queue.dequeue();
			let qsize = await queue.qsize.call();
			assert.equal(qsize.valueOf(), args._zero, "spotsFilled should still be zero");
		});

		it("Removing from queue with spotsFilled = 1", async function() {
			await queue.enqueue(accounts[0], "DENIED_SUBMISSION");

			await queue.dequeue();
			let qsize = await queue.qsize.call();
			assert.equal(qsize.valueOf(), args._zero, "spotsFilled should still be zero");

			let isEmpty = await queue.empty.call();
			assert.equal(isEmpty, true, "Queue is empty");
		});

		it("Removing from queue with spotsFilled = 4", async function () {
			await queue.enqueue(accounts[0],"1");
			await queue.enqueue(accounts[1],"2");
			await queue.enqueue(accounts[2],"3");
			await queue.enqueue(accounts[3],"4");

			await queue.dequeue();
			let qsize = await queue.qsize.call();
			assert.equal(qsize.valueOf(), 3, "spotsFilled should be 3 after 1 removal");

			let first = await queue.getFirstAddress.call();
			assert.equal(first.valueOf(), accounts[1], "First user should be user 2");

			let pos = await queue.checkPlace.call({from: accounts[0]});
			assert.equal(pos.valueOf(), 0, "User 1 no longer in queue");

			pos = await queue.checkPlace.call({from: accounts[1]});
			assert.equal(pos.valueOf(), 1, "User 2 is in position 1");

			pos = await queue.checkPlace.call({from: accounts[2]});
			assert.equal(pos.valueOf(), 2, "User 3 is in position 2");

			pos = await queue.checkPlace.call({from: accounts[3]});
			assert.equal(pos.valueOf(), 3, "User 4 is in position 3");
		});
	})
});
