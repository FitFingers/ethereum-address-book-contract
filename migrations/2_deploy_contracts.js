const AddressBookFactory = artifacts.require("./AddressBookFactory.sol");

module.exports = async (deployer) => {
  await deployer.deploy(AddressBookFactory, { gasPrice: 45000000000 });
};
