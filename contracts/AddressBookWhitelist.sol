// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract AddressBookWhitelist {
    uint256 public totalContacts;
    uint256 public securityTimelock;
    uint256 public transferPrice;

    struct Contact {
        string name;
        address wallet;
        uint256 dateAdded;
    }

    // Array of Contact structs (contacts in address book)
    Contact[] public contacts;

    // Mapping to retrieve Array index from address or name
    mapping(address => uint256) public addressToIndex;
    mapping(string => uint256) public nameToIndex;

    // Address of the contract owner
    address public owner;

    constructor() {
        owner = msg.sender;
        totalContacts = 0;
        securityTimelock = 15; // in seconds
        transferPrice = 0.005 * 10**9 * 10**9; // in ETH
    }

    // MODIFIERS

    // Only the owner of the contract may call
    modifier useOnlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner may call this function"
        );
        _;
    }

    // Only permit this transaction if it securityTimelock has elapsed (since contact was added)
    modifier useContactTimelock(string calldata name) {
        uint256 date = contacts[nameToIndex[name]].dateAdded;
        require(
            block.timestamp >= date + securityTimelock,
            "This contact was added too recently"
        );
        _;
    }

    // CONTACT MANAGEMENT

    // add a user / Contact struct to the contacts Array
    function addContact(string calldata _name, address _address)
        public
        returns (uint256 createdAt)
    {
        Contact memory person = Contact(_name, _address, block.timestamp);
        contacts.push(person);
        addressToIndex[_address] = totalContacts;
        nameToIndex[_name] = totalContacts;
        totalContacts++;
        createdAt = block.timestamp;
        return createdAt;
    }

    // find and remove a contact via their address
    function removeContactByAddress(address _address)
        public
        useOnlyOwner
        returns (string memory removeName)
    {
        uint256 removeIndex = addressToIndex[_address];
        require(removeIndex < totalContacts, "Index is out of range");
        removeName = contacts[removeIndex].name;
        contacts[removeIndex] = contacts[contacts.length - 1];
        addressToIndex[contacts[contacts.length - 1].wallet] = removeIndex;
        delete addressToIndex[_address];
        contacts.pop();
        totalContacts--;
        return removeName;
    }

    // find and remove a contact via their name
    function removeContactByName(string calldata name)
        public
        useOnlyOwner
        returns (address removeAddress)
    {
        uint256 removeIndex = nameToIndex[name];
        require(removeIndex < totalContacts, "Index is out of range");
        removeAddress = contacts[removeIndex].wallet;
        contacts[removeIndex] = contacts[contacts.length - 1];
        nameToIndex[contacts[contacts.length - 1].name] = removeIndex;
        delete nameToIndex[name];
        contacts.pop();
        totalContacts--;
        return removeAddress;
    }

    // PAYMENT FUNCTIONS
    function payContactByName(string calldata name, uint256 sendValue)
        public
        payable
        useContactTimelock(name)
        useOnlyOwner
        returns (bool success)
    {
        address recipient = contacts[nameToIndex[name]].wallet;
        require(msg.value > transferPrice + sendValue, "Not enough ETH!");
        (
            bool sent, /*bytes memory data*/

        ) = recipient.call{value: sendValue}("");
        require(sent, "Failed to send Ether");
        success = true;
        return success;
    }

    function checkBalance() public view useOnlyOwner returns (uint256 amount) {
        amount = address(this).balance;
        return amount;
    }

    function withdraw() public useOnlyOwner returns (uint256 amount) {
        amount = checkBalance();
        (
            bool sent, /*data*/

        ) = msg.sender.call{value: amount}("");
        require(sent, "There was a problem while withdrawing");
        return amount;
    }
}
