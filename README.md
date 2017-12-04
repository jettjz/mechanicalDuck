# mechanicalDuck
Dapp final project for blockchain dev decal

---
## What it Does (Will do)
Mechanical Duck is a decentralized application that is based on Amazon's mechanical Turk. Mechanical Duck allows users to post tasks and pay for other users to complete tasks. Tasks/details about the tasks are kept on the InterPlanetary File System (IPFS).

For this dapp, workers are those that complete tasks and get paid, while requesters are those who post tasks and pay workers.

Mechanical Duck will have some added functionality including time-based depreciation of pay (eg, the sooner you finish a task, the more money a worker will make) and 3rd-party verification. More specifically, tasks (HITs in mechanical Turk) can be assigned a time limit and then a depreciation rate that takes affect after the time limit as well as a early-completion bonus.

Typical tasks are completed on a first-come first-serve basis (as approved by the requester or a preset 3rd-party), but tasks can also be locked to a specific worker. In this case, the worker must first pay a small fee/deposit and the worker/requester will also confirm a trusted 3rd-party to confirm completion of a task.

Example:
A person (the requester) wants someone to manually log the items on receipts that they own. They would upload their receipts and the task to IPFS and post to Mechanical Duck for a small amount of ether. Workers then can choose to complete the task and submit there work through IPFS. The first completed submission that gets approved by the requester will get the money.

Example 2:
A small shop needs a medium-sized script to help parse through a database. They need the script rather quickly, so they post to Mechanical Duck with an early bird incentive. In addition, they want to ensure that it is completed so they request an individual worker. A worker sees the post and requests to work on the task with a 3rd-party verifier, paying a small deposit in the process. The shop agrees to the 3rd-party and assigns the task to this worker. If the worker successfully completes the job early (as approved by the 3rd-party), the worker will get the reward and the bonus.

## Potential add-ons
*These tasks are ideas*
Rather than limiting a task to one worker, open the pool to a few workers who will compete to complete the task first. All of these workers will still pay a deposit. The first worker to finish will get the reward, and all the other workers will be returned a small portion of their deposit (if at all?). This would encourage a competition to complete the task.

Rating system/way to easily find a 3rd party verifyer. Have a rating system for workers and requesters (and verifiers?).

Vote-based verification of tasks. Instead of a single 3rd-party verifier, have a group of people designated as voters. These people will then vote to determine if the task was completed (perhaps incentivized to vote by a proportion of the reward?).

## Struggles
With solidity, storing IPFS hashed addresses are a huge pain because the hash is longer than 32 bytes so requires a different way to store them. I did not find a solution to this other than to deal with larger bytes sizes but I still ran into issues (specifically with returning things with this). In addition, the time testing only seems to work about 25% of the time with the truffle test (though gives the correct times in Remix/Oyente).
