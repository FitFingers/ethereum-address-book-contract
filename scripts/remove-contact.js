const HDWalletProvider = require("truffle-hdwallet-provider");
const web3 = require("web3");
const { ABI } = require("./abi");

const MNEMONIC = process.env.MNEMONIC;
const NODE_API_KEY = process.env.ALCHEMY_KEY;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
const OWNER_ADDRESS = process.env.OWNER_ADDRESS;

if (!MNEMONIC || !NODE_API_KEY || !OWNER_ADDRESS) {
  console.error(
    "Please set a mnemonic, Alchemy key, owner, and contract address."
  );
  return;
}

async function main() {
  try {
    const provider = new HDWalletProvider(
      MNEMONIC,
      `https://eth-rinkeby.alchemyapi.io/v2/${NODE_API_KEY}`
    );
    const web3Instance = new web3(provider);

    if (CONTRACT_ADDRESS) {
      const contract = new web3Instance.eth.Contract(ABI, CONTRACT_ADDRESS, {
        gasLimit: 10000000,
      });

      async function removeContact(name) {
        console.log(`Removing ${name}`);
        const gas = await contract.methods
          .removeContactByName(name)
          .estimateGas({ from: OWNER_ADDRESS /*, value: 10000000 */ });
        console.log("Gas:", gas);
        await contract.methods
          .removeContactByName(name)
          .send({ from: OWNER_ADDRESS /*, value: 10000000 */ })
          .on("transactionHash", function (hash) {
            console.log("transactionHash", hash);
          });
      }

      const [name] = process.argv.slice(2);
      removeContact(name);
    } else {
      console.error("Add correct / missing environment variables");
    }
  } catch (err) {
    console.log("ERROR", err);
  }
}

main();
