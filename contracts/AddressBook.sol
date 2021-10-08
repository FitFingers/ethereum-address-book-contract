// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./AddressBookFactory.sol";

/**
 * @title Address Book
 * @dev Store contacts and make transfers
 */
contract AddressBook {
    address public owner;
    AddressBookFactory private _factory;

    struct Contact {
        string name;
        address wallet;
    }

    // Array of Contact structs (contacts in address book)
    Contact[] private contactsArray;

    // Mapping to retrieve Array index from address or name
    mapping(string => Contact) private contacts;

    constructor(address _bookOwner) {
        owner = _bookOwner;
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

    // CONTACT MANAGEMENT

    // add a user / Contact struct to the contacts Array
    function addContact(string calldata _name, address _address)
        public
        onlyOwner
    {
        Contact memory person = Contact(_name, _address);
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

    // UPDATE VARIABLE FUNCTIONS

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
        require(msg.value >= _factory.txCost() + sendValue, "Not enough ETH!");
        (bool sent, ) = contacts[name].wallet.call{value: sendValue}("");
        require(sent, "Failed to send Ether");
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "There was a problem while withdrawing");
    }
}
