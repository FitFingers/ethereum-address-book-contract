// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./AddressBook.sol";

/**
 * @title Address Book Factory
 * @dev Create an address book to store contacts and make transfers
 */
contract AddressBookFactory {
    uint256 public accountOpenCost;
    uint256 public txCost;
    address public owner;

    mapping(address => AddressBook) private addressBooks;

    constructor() {
        owner = msg.sender;
        accountOpenCost = 0.00025 * 10**9 * 10**9; // in ETH
        txCost = 0.0001 * 10**9 * 10**9; // in ETH
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

    // Return this user's Address Book contract address
    function fetchAddressBook() public view returns (AddressBook userData) {
        userData = addressBooks[msg.sender];
        return userData;
    }

    // Create a new AddressBook struct for this user
    function createAddressBook()
        public
        payable
        returns (address contractAddress)
    {
        require(msg.value >= accountOpenCost, "Not enough ETH");
        AddressBook newBook = new AddressBook(msg.sender);
        addressBooks[msg.sender] = newBook;
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
