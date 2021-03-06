pragma solidity ^0.4.4;

import './Queue.sol';

/**
 * @title taskThirdParty
 * The mechanical Duck task system where a requester creates a task
 * and workers can submit their completion. A 3rd party verifier(s) can be set
 * during the Constructor phase and will decide by 2/3 vote
 * uses a modified Queue.sol from the Midterm
 * that handles a max number of submissions of
 * address/ipfs_hash/time_of_submission
 *
 */

contract taskThirdParty {
    address public requester;
    bytes32 public task_request;
    Queue public workerSubmissions;
    uint8 public maxSubmissions;
    uint256 public maxReward;
    uint256 public earlyBirdBonus;
    uint256 public early_bird_time;
    uint256 public start_time;
    uint256 public end_max_reward_time;
    uint256 public end_time;
    uint256 public depreciationRate; //in wei per minute
    bool public completed;
    mapping(address => uint256) balances;
    address[] submitted; //address of who to distribute money to if no item is approved
    address[] public verifiers;
    uint numVerifiers;
    mapping(address => uint8) verifierVotes;

    event rewardRaised (uint256 newReward);
    event earlyBirdRaised (uint256 newEarlyBirdBonus, uint newEarlyBirdTime);
    event taskSubmission (address worker, string ipfs_hash);
    event taskCompleted (address successfulWorker, string submission, uint256 reward);
    event completion();

    modifier timeCheck() {
        require(!completed);
        require(now<end_time);
        _;
    }

    modifier requesterOnly() {
        require(msg.sender==requester);
        _;
    }

    /* Constructor with Depreciation: creates a task as above in basic constructor
     * where depreciationRate is in Wei per minute */
    function taskThirdParty(string _ipfs_task, uint256 _durationInMinutes,
            uint8 _maxSubmissions, uint256 _depreciationRate, address[] _verifiers) payable {
        completed = false;
        requester = msg.sender;
        maxReward = msg.value;
        maxSubmissions = _maxSubmissions;
        workerSubmissions = new Queue(_maxSubmissions);
        start_time = now;
        end_time = start_time + (_durationInMinutes * 1 minutes);
        task_request = stringToBytes32(_ipfs_task);
        early_bird_time = start_time;
        end_max_reward_time = end_time;
        depreciationRate = _depreciationRate;
        earlyBirdBonus = 0;
        submitted.push(msg.sender);
        numVerifiers = 0;
        verifiers = _verifiers;
    }

    function getVerifiers() returns (address[]) {
        return verifiers;
    }

    // Source https://ethereum.stackexchange.com/questions/2519/how-to-convert-a-bytes32-to-string
    function bytes32ToString(bytes32 x) constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    //Source: https://ethereum.stackexchange.com/questions/9142/how-to-convert-a-string-to-bytes32
    function stringToBytes32(string memory source) returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }


    function getRequestHash() constant returns(string) {
        return bytes32ToString(task_request);
    }

    function getNumSubmissions() constant returns(uint) {
        return workerSubmissions.qsize();
    }

    function isFull() constant returns(bool) {
        return workerSubmissions.isFull();
    }

    function getBalance(address _user) constant returns(uint256) {
        return balances[_user];
    }

    function getBalance() constant returns(uint256) {
        return balances[msg.sender];
    }

    //Outdated
    function getQSize() constant returns(uint) {
        return workerSubmissions.qsize();
    }

    /* Adds to maxReward. Note that this will be taken into account for the
     * depreciationRate as well */
    function addReward() payable requesterOnly timeCheck {
        maxReward = maxReward + msg.value;
    }

    /* either creates or adds to earlyBirdBonus (can add to by setting _durationInMinutes=0).
     * This will not affect maxReward and the depreciationRate */
    function addEarlyBird(uint _durationInMinutes) payable requesterOnly timeCheck {
        early_bird_time = early_bird_time + (_durationInMinutes * 1 minutes);
        require(early_bird_time <= end_time);
        require(early_bird_time > now);
        earlyBirdBonus = earlyBirdBonus + msg.value;
    }

    /* Adds a new submission to the queue */
    function submit(string task_submission) external timeCheck returns(bool) {
        bytes32 submission = stringToBytes32(task_submission);
        if (workerSubmissions.enqueue(msg.sender, submission)){
            taskSubmission(msg.sender, task_submission);
            submitted.push(msg.sender);
            return true;
        }
        else {
            return false;
        }
    }

    /* returns the ipfs hash of the first submission from a worker */
    function getFirstSubmission() constant returns(string) {
        require(workerSubmissions.qsize()>0);
        return bytes32ToString(workerSubmissions.getFirstSubmission());
    }

    /* returns the address of the first submission from a worker */
    function getFirstAddress() constant returns(address) {
        require(workerSubmissions.qsize()>0);
        return workerSubmissions.getFirstAddress();
    }

    function approveFirstSubmission() private {
        require(!completed);
        require(workerSubmissions.qsize()>1);
        address worker = workerSubmissions.getFirstAddress();
        bytes32 submission = workerSubmissions.getFirstSubmission();
        uint submissionTime = workerSubmissions.getFirstTime();
        workerSubmissions.dequeue();
        completed = true;
        uint256 reward = 0;
        if (submissionTime < early_bird_time) {
            reward += earlyBirdBonus;
        }
        if (submissionTime < end_max_reward_time) {
            reward += maxReward;
        } else {
            uint256 temp = maxReward;
            temp -= (end_time - submissionTime)*60*depreciationRate;
            assert(temp>0);
            reward+=temp;
        }
        balances[worker] += reward;
        balances[requester] += this.balance - reward;
        taskCompleted(worker, bytes32ToString(submission), reward);
    }

    // Do I need to add anything else to this?
    function denyFirstSubmission() private {
        require(workerSubmissions.qsize()>1);
        workerSubmissions.dequeue();
    }

    /* Allows a user to vote for approving a submission. Returns true or false
     * depending on whether the user is a verifier or not, but will change the mapping
     * no matter what */
    function vote(bool isApprove) returns(bool) {
        if (isApprove) {
            verifierVotes[msg.sender] = 2;
        } else {
            verifierVotes[msg.sender] = 1;
        }
        for (uint i = 0; i < numVerifiers; i++) {
            if (verifiers[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    /* this function will distribute all wei evenly between requester and those in
     * queue if it is past 5 days after end_time */
    function checkTime() external {
        this.checkVotes();
        if ((now > end_time) && (!completed)) {
            completed = true;
            // Do I need to change this line?
            uint256 value = this.balance/submitted.length;
            for (uint i = 0; i < submitted.length; i++) {
                balances[submitted[i]] += value;
            }
        }
    }

    /*
     * checks the votes and will determine if the first submission was accepted.
     * returns 0 if not enough verifiers voted (quorum of >50% needed) regardless
     * of result of vote result.
     * Returns 1 for failure of first the first submission and 2 for the approval of
     * first submission. A vote of at least 2/3 of votes needs to be met to approve.
     *
     * If the quorum was not met, the function returns 0 and does nothing
     * If the submission is rejected, the first submission is dequeued and votes are reset
     * If submission is approved, the first submission gets the reward and the task is completed
     */
    function checkVotes() external returns(uint8) {
        uint numVotes = 0;
        uint numApprove = 0;
        uint numReject = 0;
        for(uint i = 0; i < numVerifiers; i++) {
            uint8 user_vote = verifierVotes[verifiers[i]];
            if (user_vote==0) {
                numVotes++;
                if (user_vote==1) {
                    numReject++;
                } else if (user_vote==2) {
                    numApprove++;
                }
            }
        }
        if (numVotes <= (numVerifiers/2)) {
            return 0;
        }
        if (numApprove >= (2*numVotes/3)) {
            approveFirstSubmission();
            return 2;
        }
        denyFirstSubmission();
        //resets votes
        for(uint j = 0; i < numVerifiers; i++) {
            verifierVotes[verifiers[j]] = 0;
        }
        return 1;
    }

    /* withdraws balances after completion */
    function withdrawFunds() external returns(bool) {
        require(completed);
        uint refund = balances[msg.sender];
        balances[msg.sender] = 0;
        if (refund <= 0) {
            return false;
        }
        msg.sender.transfer(refund);
        return true;
    }

    function() payable {
        revert();
    }
}
