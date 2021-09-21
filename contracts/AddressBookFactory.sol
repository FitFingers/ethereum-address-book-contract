// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./AddressBook.sol";

/**
 * @title Address Book Factory
 * @dev Create an address book to store contacts and make transfers
 */
contract AddressBookFactory {
    uint256 public totalAddressBooks;
    uint256 public accountOpenCost;
    uint256 public txCost;

    // TODO: is this bloat? Can't I just use a mapping? If so, how do I handle verification such as existing account?
    // Array of existing AddressBooks
    AddressBook[] private addressBooks; // onlyOwner?

    // Take user address, return index of AddressBook => used to fetch data on F/E
    mapping(address => uint256) private addressToIndex;

    // Get this user's Address Book and return it
    function fetchAddressBook()
        public
        view
        customerOrOwner
        returns (AddressBook userData)
    {
        userData = addressBooks[addressToIndex[msg.sender]];
        return userData;
    }

    // Address of the contract owner => required for frontend auth
    address public owner;

    constructor() {
        owner = msg.sender;
        totalAddressBooks = 0;
        accountOpenCost = 0.00025 * 10**9 * 10**9; // in ETH
        txCost = 0.0001 * 10**9 * 10 * 9; // in ETH

        // first address book belongs to owner;
        addressBooks.push(new AddressBook(msg.sender));
        totalAddressBooks++;
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

    // Only permitted for customers or the owner
    modifier customerOrOwner() {
        require(
            addressToIndex[msg.sender] > 0 || msg.sender == owner,
            "You must have an account or be the owner to use this"
        );
        _;
    }

    // Only permitted for new/non-customers
    modifier noncustomersOnly() {
        require(
            addressToIndex[msg.sender] == 0 && msg.sender != owner,
            "You already have an account"
        );
        _;
    }

    // ADDRESS BOOK MANAGEMENT

    // Create a new AddressBook struct for this user
    function createAddressBook()
        public
        payable
        noncustomersOnly
        returns (address contractAddress)
    {
        require(msg.value >= accountOpenCost);
        AddressBook newBook = new AddressBook(msg.sender);
        addressBooks.push(newBook);
        addressToIndex[msg.sender] = totalAddressBooks;
        totalAddressBooks++;
        contractAddress = address(newBook);
        return contractAddress;
    }

    // UPDATE VARIABLE FUNCTIONS

    // Update the price to open an account here
    function updateAccountOpenCost(uint256 _accountOpenCost) public onlyOwner {
        accountOpenCost = _accountOpenCost;
    }

    // Update the price to interact with this contract
    function updateTransactionCost(uint256 _txCost) public onlyOwner {
        txCost = _txCost;
    }

    // PAYMENT FUNCTIONS

    function checkBalance() public view onlyOwner returns (uint256 amount) {
        amount = address(this).balance;
        return amount;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: checkBalance()}("");
        require(sent, "There was a problem while withdrawing");
    }
}
