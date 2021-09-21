// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./AddressBookFactory.sol";

/**
 * @title Address Book
 * @dev Store contacts and make transfers
 */
contract AddressBook {
    uint256 private _totalContacts;
    uint256 private _securityTimelock;
    uint256 private _lastTimelockUpdate;
    AddressBookFactory private _factory;

    struct Contact {
        string name;
        address wallet;
        uint256 dateAdded;
    }

    // Array of Contact structs (contacts in address book)
    Contact[] private contacts;

    // Mapping to retrieve Array index from address or name
    mapping(address => uint256) private addressToIndex;
    mapping(string => uint256) private nameToIndex;

    // Address of the contract owner => TODO: does this need to be public?
    address public owner;

    constructor(address _bookOwner) {
        owner = _bookOwner;
        _totalContacts = 0;
        _securityTimelock = 90; // in seconds
        _lastTimelockUpdate = block.timestamp;
        _factory = AddressBookFactory(msg.sender);
    }

    // MODIFIERS

    // Only the owner of the contract may call
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner may call this function"
        );
        _;
    }

    // Only permitted after x time (z.B. new contacts can't be paid for at least this amount of time)
    modifier timelockElapsed() {
        require(
            block.timestamp >= _lastTimelockUpdate + _securityTimelock,
            "You must wait for the security timelock to elapse before this is permitted"
        );
        _;
    }

    // CONTACT MANAGEMENT

    // add a user / Contact struct to the contacts Array
    function addContact(string calldata _name, address _address)
        public
        onlyOwner
    {
        Contact memory person = Contact(_name, _address, block.timestamp);
        contacts.push(person);
        addressToIndex[_address] = _totalContacts;
        nameToIndex[_name] = _totalContacts;
        _totalContacts++;
    }

    // find and remove a contact via their name
    function removeContactByName(string calldata name) public onlyOwner {
        uint256 removeIndex = nameToIndex[name];
        require(removeIndex < _totalContacts, "Index is out of range");
        contacts[removeIndex] = contacts[contacts.length - 1];
        nameToIndex[contacts[contacts.length - 1].name] = removeIndex;
        delete nameToIndex[name];
        contacts.pop();
        _totalContacts--;
    }

    // Get all contact data for this AddressBook
    function readAllContacts()
        public
        view
        onlyOwner
        returns (Contact[] memory)
    {
        Contact[] memory result = new Contact[](_totalContacts);
        for (uint256 i = 0; i < _totalContacts; i++) {
            result[i] = contacts[i];
        }
        return result;
    }

    function readTotalContacts()
        public
        view
        onlyOwner
        returns (uint256 totalContacts)
    {
        totalContacts = _totalContacts;
        return totalContacts;
    }

    function readSecurityTimelock()
        public
        view
        onlyOwner
        returns (uint256 securityTimelock)
    {
        securityTimelock = _securityTimelock;
        return securityTimelock;
    }

    function readLastTimelockUpdate()
        public
        view
        onlyOwner
        returns (uint256 lastTimelockUpdate)
    {
        lastTimelockUpdate = _lastTimelockUpdate;
        return lastTimelockUpdate;
    }

    // UPDATE VARIABLE FUNCTIONS

    // Update this user's personal timelock
    function updateTimelock(uint256 duration) public onlyOwner timelockElapsed {
        _securityTimelock = duration;
        _lastTimelockUpdate = block.timestamp;
    }

    // PAYMENT FUNCTIONS

    // Get the latest TX cost from the Factory
    function checkTxCost() public view returns (uint256 _price) {
        _price = _factory.txCost();
        return _price;
    }

    // Transfer ETH to a contact
    function payContactByName(string calldata name, uint256 sendValue)
        public
        payable
        onlyOwner
    {
        Contact memory recipient = contacts[nameToIndex[name]];
        require(
            block.timestamp >= recipient.dateAdded + _securityTimelock,
            "This contact was added too recently"
        );
        require(msg.value >= _factory.txCost() + sendValue, "Not enough ETH!");
        (bool sent, ) = recipient.wallet.call{value: sendValue}("");
        require(sent, "Failed to send Ether");
    }

    // Leaving these two functions in in case of accidental transfer of money into contract
    function checkBalance() public view onlyOwner returns (uint256 amount) {
        amount = address(this).balance;
        return amount;
    }

    function withdraw() public onlyOwner {
        uint256 amount = checkBalance();
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "There was a problem while withdrawing");
    }
}
