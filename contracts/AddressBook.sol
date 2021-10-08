// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Address Book
 * @dev Store contacts and make transfers
 */
contract AddressBook {
    address public owner;

    struct Contact {
        bytes32 name;
        address wallet;
    }

    // Array of Contact structs (contacts in address book)
    Contact[] private contactsArray;

    // Mapping to retrieve Array index from address or name
    mapping(bytes32 => address) private contacts;

    constructor(address _bookOwner) {
        owner = _bookOwner;
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
    function addContact(bytes32 _name, address _address) public onlyOwner {
        contacts[_name] = _address;
        contactsArray.push(Contact(_name, _address));
    }

    // find and remove a contact via their name
    // TODO: must remove contact from array as well!
    function removeContactByName(bytes32 name) public onlyOwner {
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
        totalContacts = contactsArray.length; // TODO: this won't work correctly without remove function
        return totalContacts;
    }

    // PAYMENT FUNCTIONS

    // Transfer ETH to a contact
    function payContactByName(bytes32 name, uint256 sendValue)
        public
        payable
        onlyOwner
    {
        require(msg.value >= 33000000000000 + sendValue, "Not enough ETH!");
        (bool sent, ) = contacts[name].call{value: sendValue}("");
        require(sent, "Failed to send Ether");
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "There was a problem while withdrawing");
    }
}
