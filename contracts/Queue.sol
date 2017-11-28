pragma solidity ^0.4.15;

/**
 * @title Queue
 */

contract Queue {
	/* State variables */
	uint8 size = 5;
	uint8 spotsFilled;
	address[] participants;
	uint limit;

    struct Submission {
        address worker;
        string ipfs_hash;
        uint256 time;
    }

	event limitReached();

	function Queue(uint _size) {
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
	function getFirstSubmission() constant returns(string) {
		require(spotsFilled>0);
		return queueList[0].ipfs_hash;
	}

    /* Returns the timestamp of the person in the front of the queue */
	function getFirstTime() constant returns(uint256) {
		require(spotsFilled>0);
		return queueList[0].time;
	}

    /* Returns the address of the person in the front of the queue */
	function getFirstAddress() constant returns(Submission) {
		require(spotsFilled>0);
		return queueList[0].worker;
	}

	/* Allows `msg.sender` to check their position in the queue */
	function checkPlace() constant returns(uint8) {
		for (uint8 i = 0; i < spotsFilled; i++) {
			if (queueList[i] == msg.sender) {
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
			delete participants[spotsFilled];
			delete times[spotsFilled];
		}
	}

	/* Places Submission in the first available position in queueList */
	function enqueue(address addr, string submission) returns(bool){
		if (spotsFilled < size) {
			spotsFilled += 1;
            Submission s = Submission(addr, submission, now);
            queueList[spotsFilled - 1] = s;
            if (spotsFilled==size) {
                limitReached();
            }
            return true;
		} else {
            return false;
        }
	}
}