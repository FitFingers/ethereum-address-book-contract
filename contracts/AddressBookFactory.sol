// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./AddressBook.sol";

/**
 * @title Address Book Factory
 * @dev Create an address book to store contacts and make transfers
 */
contract AddressBookFactory {
    uint256 public totalAddressBooks;
    uint256 public creationPrice;
    uint256 public txCost;

    // Array of existing AddressBooks
    AddressBook[] public addressBooks; // onlyOwner?

    // Address of the contract owner
    address public owner;

    constructor() {
        owner = msg.sender;
        totalAddressBooks = 0;
        creationPrice = 0.0025 * 10**9 * 10**9; // in ETH
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

    // add a user / Contact struct to the contacts Array
        // payable
    function createAddressBook()
        public
        returns (address contractAddress)
    {
        // require(msg.value >= creationPrice);
        AddressBook newBook = new AddressBook(msg.sender);
        addressBooks.push(newBook);
        totalAddressBooks++;
        contractAddress = address(newBook);
        return contractAddress;
    }
    
    // UPDATE VARIABLE FUNCTIONS

    function updateTransactionCost(uint256 _txCost) public onlyOwner {
        txCost = _txCost;
    }

    // PAYMENT FUNCTIONS

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
