pragma solidity ^0.4.19;

/**
 * @title Queue
 */

contract Queue {
	/* State variables */
	uint8 size = 5;
	uint8 spotsFilled;
	uint limit;
	Submission[] queueList;

    struct Submission {
        address worker;
        bytes32 ipfs_hash;
        uint256 time;
    }

	event limitReached();

	function Queue(uint8 _size) {
		spotsFilled = 0;
        size = _size;
		queueList = new Submission[](size);
	}

	/* Returns the number of people waiting in line */
	function qsize() constant returns(uint8) {
		return spotsFilled;
	}

	/* Returns whether the queue is empty or not */
	function empty() constant returns(bool) {
		return (spotsFilled == 0);
	}

    /* Returns whether the queue is full or not */
    function isFull() constant returns(bool) {
        return (spotsFilled == size);
    }

	/* Returns the full submission struct of the person in the front of the queue */
	function getFirst() constant returns(Submission) {
		require(spotsFilled>0);
		return queueList[0];
	}

    /* Returns the address of the person in the front of the queue */
	function getFirstAddress() constant returns(address) {
		require(spotsFilled>0);
		return queueList[0].worker;
	}

    /* Returns the address of the person in the front of the queue */
	function getFirstSubmission() constant returns(bytes32) {
		require(spotsFilled>0);
		return queueList[0].ipfs_hash;
	}

    /* Returns the timestamp of the person in the front of the queue */
	function getFirstTime() constant returns(uint256) {
		require(spotsFilled>0);
		return queueList[0].time;
	}

	/* Allows `msg.sender` to check their position in the queue */
	function checkPlace() constant returns(uint8) {
		for (uint8 i = 0; i < spotsFilled; i++) {
			if (queueList[i].worker == msg.sender) {
				return i + 1;
			}
		}
		return 0;
	}

	/* Removes the first person in line */
	function dequeue() {
		if (spotsFilled != 0) {
			for (uint i = 1; i < spotsFilled; i++) {
				queueList[i - 1] = queueList[i];
			}
			spotsFilled -= 1;
			delete queueList[spotsFilled];
		}
	}

	/* Places Submission in the first available position in queueList */
	function enqueue(address addr, bytes32 submission) returns(bool){
		if (spotsFilled < size) {
			spotsFilled += 1;
            queueList[spotsFilled - 1] = Submission(addr, submission, now);
            if (spotsFilled==size) {
                limitReached();
            }
            return true;
		} else {
            return false;
        }
	}
}
