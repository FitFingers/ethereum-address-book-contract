// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./AddressBookFactory.sol";

/**
 * @title Address Book
 * @dev Store contacts and make transfers
 */
contract AddressBook {
    uint256 private _securityTimelock;
    uint256 private _lastTimelockUpdate;
    address public owner;
    AddressBookFactory private _factory;

    struct Contact {
        string name;
        address wallet;
        uint256 dateAdded;
    }

    // Array of Contact structs (contacts in address book)
    Contact[] private contactsArray;

    // Mapping to retrieve Array index from address or name
    mapping(string => Contact) private contacts;

    constructor(address _bookOwner) {
        owner = _bookOwner;
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
        contacts[_name] = person;
        contactsArray.push(person);
    }

    // find and remove a contact via their name
    // TODO: must remove contact from array as well!
    function removeContactByName(string calldata name) public onlyOwner {
        delete contacts[name];
    }

    // Get all contact data for this AddressBook
    function readContactArray()
        public
        view
        onlyOwner
        returns (Contact[] memory _contacts)
    {
        _contacts = contactsArray;
        return _contacts;
    }

    function readTotalContacts()
        public
        view
        onlyOwner
        returns (uint256 totalContacts)
    {
        totalContacts = contactsArray.length; // TODO: this won't work without remove function
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
        require(
            block.timestamp >= contacts[name].dateAdded + _securityTimelock,
            "This contact was added too recently"
        );
        require(msg.value >= _factory.txCost() + sendValue, "Not enough ETH!");
        (bool sent, ) = contacts[name].wallet.call{value: sendValue}("");
        require(sent, "Failed to send Ether");
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "There was a problem while withdrawing");
    }
}
