const AddressBookFactory = artifacts.require("./AddressBookFactory.sol");

module.exports = async (deployer) => {
  await deployer.deploy(AddressBookFactory, { gas: 5000000 });
};
