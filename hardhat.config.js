require("@nomiclabs/hardhat-ethers");
require("@tenderly/hardhat-tenderly");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
require("@nomiclabs/hardhat-truffle5");

const { utils } = require("ethers");

const PRIVATE_KEY = process.env.PRIVATE_KEY;
// const PRIVATE_KEY_GANACHE = process.env.PRIVATE_KEY_GANACHE;
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "goerli",
  solidity: {
    compilers: [
      {
        version: "0.7.0",
      },
    ],
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  networks: {
    goerli: {
      url: "https://small-holy-wave.ethereum-goerli.quiknode.pro/2136bd79203bbb3a515cf651c5de89e268d60b8d/",
      accounts: [`0x${PRIVATE_KEY}`]
    },
    // testnet: {
    //   url: "https://data-seed-prebsc-1-s1.binance.org:8545",
    //   chainId: 97,
    //   gasPrice: 20000000000,
    //   accounts: [`0x${PRIVATE_KEY}`],
    // },
    // localhost: {
    //   url: `http://localhost:8545`,
    //   accounts: [`0x${PRIVATE_KEY_GANACHE}`],
    //   timeout: 150000,
    //   gasPrice: parseInt(utils.parseUnits("132", "gwei")),
    // },
    mainnet: {
      url: "https://late-shy-breeze.quiknode.pro/cb2c775af8638f722111f91d72e5a80ccb2f0f07/",
      chainId: 1,
      accounts: [`0x${PRIVATE_KEY}`],
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
    /*apiKey: process.env.BSCSCAN_API_KEY,*/
    apiKey: '2NNNEK3BB6M6XCC2YKQZJAHYVP6MVAMW1N'
  },
  tenderly: {
    project: process.env.TENDERLY_PROJECT,
    username: process.env.TENDERLY_USERNAME,
  },
};
