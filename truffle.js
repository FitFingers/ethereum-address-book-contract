const HDWalletProvider = require("truffle-hdwallet-provider");

const MNEMONIC = process.env.MNEMONIC;
const NODE_API_KEY = process.env.ALCHEMY_KEY;

const needsNodeAPI =
  process.env.npm_config_argv &&
  (process.env.npm_config_argv.includes("rinkeby") ||
    process.env.npm_config_argv.includes("live"));

if ((!MNEMONIC || !NODE_API_KEY) && needsNodeAPI) {
  console.error("Please set a mnemonic and ALCHEMY_KEY");
  process.exit(0);
}

const rinkebyNodeUrl = `https://eth-rinkeby.alchemyapi.io/v2/${NODE_API_KEY}`;

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
    rinkeby: {
      provider: function () {
        return new HDWalletProvider(MNEMONIC, rinkebyNodeUrl);
      },
      gas: 5000000,
      network_id: 4,
    },
  },
  mocha: {
    reporter: "eth-gas-reporter",
    reporterOptions: {
      currency: "USD",
      gasPrice: 2,
    },
  },
  compilers: {
    solc: {
      version: "^0.8.0",
      settings: {
        optimizer: {
          enabled: true,
          runs: 20, // Optimize for how many times you intend to run the code
        },
      },
    },
  },
  plugins: ["truffle-plugin-verify"],
  api_keys: {
    etherscan: "ETHERSCAN_API_KEY_FOR_VERIFICATION",
  },
};
