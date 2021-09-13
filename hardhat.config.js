require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");
const { removeConsoleLog } = require("hardhat-preprocessor");

module.exports = {
  networks: {
    hardhat: {
      accounts: {
        count: 20,
        mnemonic: "drip wheat survey engine mercy punch fit mask quality embrace lens try"
      },
      allowUnlimitedContractSize: true,
      initialBaseFeePerGas: 0, // workaround from https://github.com/sc-forks/solidity-coverage/issues/652#issuecomment-896330136 . Remove when that issue is closed.
    },
    mainnet: {
      url: process.env.BSC_MAINNET_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
    testnet: {
      url: process.env.BSC_TESTNET_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
  },
  watcher: {
    compilation: {
      tasks: ["compile"],
      files: ["./contracts"],
      verbose: true,
    },
    ci: {
      tasks: ["clean", {command: "compile", params: {quiet: true}}, {
        command: "test",
        params: {noCompile: true, testFiles: ["testfile.ts"]}
      }],
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  solidity: {
    version: "0.8.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 999999
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  preprocess: {
    eachLine: removeConsoleLog((hre) => hre.network.name !== "hardhat" && hre.network.name !== "localhost")
  },
  mocha: {
    timeout: 180000
  }
};