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

    // Take user address, return index of AddressBook => used to fetch data on F/E
    mapping(address => AddressBook) private addressBooks;

    // Return this user's Address Book contract address. Default is 0x0000000000000000000000000000000000000000
    function fetchAddressBook() public view returns (AddressBook userData) {
        userData = addressBooks[msg.sender];
        return userData;
    }

    // Address of the contract owner => required for frontend auth
    address public owner;

    constructor() {
        owner = msg.sender;
        totalAddressBooks = 0;
        accountOpenCost = 0.00025 * 10**9 * 10**9; // in ETH
        txCost = 0.0001 * 10**9 * 10**9; // in ETH

        // first address book belongs to owner;
        addressBooks[msg.sender] = new AddressBook(msg.sender);
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

    // ADDRESS BOOK MANAGEMENT

    // Create a new AddressBook struct for this user
    function createAddressBook()
        public
        payable
        returns (address contractAddress)
    {
        require(msg.value >= accountOpenCost, "Not enough ETH");
        AddressBook newBook = new AddressBook(msg.sender);
        addressBooks[msg.sender] = newBook;
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
