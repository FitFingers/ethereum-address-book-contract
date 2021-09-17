const AddressBookWhitelist = artifacts.require("./AddressBookWhitelist.sol");

module.exports = async (deployer) => {
  await deployer.deploy(AddressBookWhitelist, { gas: 5000000 });
};
