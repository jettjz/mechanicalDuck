var taskStandard = artifacts.require("./taskStandard.sol");
var Queue = artifacts.require("./Queue.sol");
var taskThirdParty = artifacts.require("./taskThirdParty.sol");

module.exports = function(deployer) {
	deployer.deploy(taskStandard);
	deployer.deploy(Queue);
	deployer.deploy(taskThirdParty);
};
