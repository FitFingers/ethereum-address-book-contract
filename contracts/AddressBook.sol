// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Address Book
 * @dev Store contacts and make transfers
 */
contract AddressBook {
    uint256 public totalContacts;
    uint256 public securityTimelock;
    uint256 public txCost;
    uint256 public lastTimelockUpdate;

    struct Contact {
        string name;
        address wallet;
        uint256 dateAdded;
    }

    // Array of Contact structs (contacts in address book)
    Contact[] public contacts; // onlyOwner

    // Mapping to retrieve Array index from address or name
    mapping(address => uint256) public addressToIndex;
    mapping(string => uint256) public nameToIndex;

    // Address of the contract owner
    address public owner;

    constructor(address _bookOwner) {
        owner = _bookOwner;
        totalContacts = 0;
        securityTimelock = 90; // in seconds
        txCost = 0.005 * 10**9 * 10**9; // in ETH
        lastTimelockUpdate = block.timestamp;
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

    modifier timelockElapsed() {
        require(
            block.timestamp >= lastTimelockUpdate + securityTimelock,
            "You must wait for the security timelock to elapse before this is permitted"
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
        onlyOwner
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
        onlyOwner
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

    function readAllContacts()
        public
        view
        onlyOwner
        returns (Contact[] memory)
    {
        Contact[] memory result = new Contact[](totalContacts);
        for (uint256 i = 0; i < totalContacts; i++) {
            result[i] = contacts[i];
        }
        return result;
    }

    // UPDATE VARIABLE FUNCTIONS

    function updateTimelock(uint256 duration) public timelockElapsed {
        securityTimelock = duration;
        lastTimelockUpdate = block.timestamp;
    }

    function updateTransactionCost(uint256 newTxCost) public timelockElapsed {
        txCost = newTxCost;
    }

    // PAYMENT FUNCTIONS

    function payContactByName(string calldata name, uint256 sendValue)
        public
        payable
        onlyOwner
        returns (bool success)
    {
        Contact memory recipient = contacts[nameToIndex[name]];
        require(
            block.timestamp >= recipient.dateAdded + securityTimelock,
            "This contact was added too recently"
        );
        require(msg.value >= txCost + sendValue, "Not enough ETH!");
        (
            bool sent, /*bytes memory data*/

        ) = recipient.wallet.call{value: sendValue}("");
        require(sent, "Failed to send Ether");
        success = true;
        return success;
    }

    function checkBalance() public view onlyOwner returns (uint256 amount) {
        amount = address(this).balance;
        return amount;
    }

    function withdraw() public onlyOwner returns (uint256 amount) {
        amount = checkBalance();
        (
            bool sent, /*data*/

        ) = msg.sender.call{value: amount}("");
        require(sent, "There was a problem while withdrawing");
        return amount;
    }
}
