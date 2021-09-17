# Address Book Whitelist

## A Solidity smart contract for storing names and addresses

<hr>

### Setup

1. Clone the repo
2. Initiliase an Alchemy project (if not running an Ethereum node)
3. Add a MetaMask mnemonic to .env
4. Add the Alchemy project's API key to the .env
5. Source these variables in the terminal session
6. Install the dependencies using `yarn`
7. Compile the smart contracts by running `yarn compile`
8. Deploy the smart contracts by running `yarn deploy:migrate`
9. After deployment, add the contract and owner address to the `.env`


### Gotchas

- The `.env` file has to use the format `export KEY="VALUE"`
