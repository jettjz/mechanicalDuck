pragma solidity ^0.4.19;

import './Queue.sol';

/**
 * @title taskStandard
 * The simple mechanical Duck task system where a requester creates a task
 * and workers can submit their completion of the task without any deposits
 * uses a modified Queue.sol from the Midterm
 * that handles a max number of submissions of
 * address/ipfs_hash/time_of_submission
 *
 * TODO:
 * How to handle requester never accepting a submission
 *      currently, until either everybody in the queue is denied
 *      or one is accepted, no one can withdraw any funds including requester
 * How to handle overloading of queue
 */

contract taskStandard {
	address public requester;
    string public task_request;
    Queue public workerSubmissions;
    uint8 public maxSubmissions;
    uint256 public maxReward;
    uint256 public earlyBirdBonus;
    uint public early_bird_time;
    uint public start_time;
    uint public end_max_reward_time;
    uint public end_time;
    uint256 public depreciationRate; //in wei per minute
    bool completed;
    mapping(address => uint256) balances;
    address[] submitted; //address of who to distribute money to if no item is approved

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

    /* Basic Constructor: no earlyBirdBonus, no depreciation, simple reward for completion
     * of task. The ipfs_task is the location of the task description/any necessary items for the task
     * Note that an earlyBirdBonus/higher reward can be set by the requester later */
    function payable Crowdsale(string _ipfs_task, uint _durationInMinutes, uint8 _maxSubmissions) {
        deployed = false;
        requester = msg.sender;
        maxReward = msg.value;
        maxSubmissions = _maxSubmissions;
        workerSubmissions = new Queue(_maxSubmissions);
        start_time = now;
        end_time = start_time + (_durationInMinutes * 1 minutes);
        task_request = _ipfs_task;
        early_bird_time = start_time;
        uint public end_max_reward_time = end_time;
        depreciationRate = 0;
        earlyBirdBonus = 0;
        submitted.push(msg.sender);
    }

    /* Constructor with Depreciation: creates a task as above in basic constructor
     * where depreciationRate is in Wei per minute */
    function payable Crowdsale(string _ipfs_task, uint _durationInMinutes,
            uint8 _maxSubmissions, uint256 _depreciationRate) {
        deployed = false;
        requester = msg.sender;
        maxReward = msg.value;
        maxSubmissions = _maxSubmissions;
        workerSubmissions = new Queue(_maxSubmissions);
        start_time = now;
        end_time = start_time + (_durationInMinutes * 1 minutes);
        task_request = _ipfs_task;
        early_bird_time = start_time;
        uint public end_max_reward_time = end_time;
        depreciationRate = _depreciationRate;
        earlyBirdBonus = 0;
        submitted.push(msg.sender);
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

    /* Adds to maxReward. Note that this will be taken into account for the
     * depreciationRate as well */
    function payable addReward() requesterOnly, timeCheck {
        maxReward = maxReward + msg.value;
    }

    /* either creates or adds to earlyBirdBonus (can add to by setting _durationInMinutes=0).
     * This will not affect maxReward and the depreciationRate */
    function payable addEarlyBird(uint _durationInMinutes) requesterOnly, timeCheck {
        early_bird_time = early_bird_time + (_durationInMinutes * 1 minutes);
        require(early_bird_time <= end_time);
        require(early_bird_time > now);
        earlyBirdBonus = earlyBirdBonus + msg.value;
    }

    /* Adds a new submission to the queue */
    function submit(string task_submission) external timeCheck returns(bool) {
        if (workerSubmissions.enqueue(msg.sender, task_submission)){
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
        require(workerSubmissions.qsize()>1);
        return workerSubmissions.getFirstSubmission();
    }

    /* returns the address of the first submission from a worker */
    function getFirstAddress() constant returns(address) {
        require(workerSubmissions.qsize()>1);
        return workerSubmissions.getFirstAddress();
    }

    function approveFirstSubmission() requesterOnly {
        require(!completed);
        require(workerSubmissions.qsize()>1);
        address worker = workerSubmissions.getFirstAddress();
        string submission = workerSubmissions.getFirstSubmission();
        uint submissionTime = workerSubmissions.getFirstTime();
        workerSubmissions.dequeue(); //Do I need to dequeue this?
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
        balances[requester] += this.value - reward;
        taskCompleted(worker, submission);
    }

    // Do I need to add anything else to this?
    function denyFirstSubmission() requesterOnly {
        require(workerSubmissions.qsize()>1);
        workerSubmissions.dequeue();
    }

    /* this function will distribute all wei evenly between requester and those in
     * queue if it is past 5 days after end_time */
    function checkTime() external {
        if (now > end_time) && (!completed) {
            completed = true;
            // Do I need to change this line?
            uint256 value = this.value/submitted.length;
            for (int i = 0; i < submitted.length; i++) {
                balances[submitted[i]] += value;
            }
        }
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
