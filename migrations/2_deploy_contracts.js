const Counter = artifacts.require("./Counter.sol");

module.exports = async (deployer) => {
  await deployer.deploy(Counter, { gas: 5000000 });
};
