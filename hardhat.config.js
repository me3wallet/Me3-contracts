require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@tenderly/hardhat-tenderly");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-truffle5");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-contract-sizer');
const { utils } = require("ethers");

const PRIVATE_KEY = '0x' + process.env.PRIVATE_KEY;
const PRIVATE_KEY_GANACHE = '0x' + process.env.PRIVATE_KEY_GANACHE;
/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const settings = {
  optimizer: {
    enabled: true,
    runs: 200,
  },
};
module.exports = {
  defaultNetwork: "localhost",
  solidity: {
    compilers: [
      {
        version: "0.7.0",
        settings,
      },
      {
        version: "0.8.0",
        settings,
      },
      {
        version: "0.8.2",
        settings,
      },
    ]
  },
  networks: {
    rinkeby: {
      url: "https://eth-rinkeby.alchemyapi.io/v2/wy0gq_G7RtJXeUgcjkADHpoVAYeFHp2o",
      accounts: [PRIVATE_KEY]
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [PRIVATE_KEY],
    },
    localhost: {
      url: `http://localhost:8545`,
      accounts: [PRIVATE_KEY_GANACHE],
      timeout: 150000,
      gasPrice: parseInt(utils.parseUnits("132", "gwei")),
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      accounts: [PRIVATE_KEY],
    },
    hardhat: {
      forking: {
        url: `https://bsc-dataseed.binance.org/`,
        blockNumber: 6674768,
      },
      blockGasLimit: 12000000,
    },
  },
  etherscan: {
    // apiKey: 'Z8BMQVST4M1351EH1W5VZRBMFG1FD4DPWD',
    apiKey: process.env.BSCSCAN_API_KEY,
  },
  tenderly: {
    project: process.env.TENDERLY_PROJECT,
    username: process.env.TENDERLY_USERNAME,
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true
  }
};
