const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const admin = "0x756ee6a0033adFa3c30893E13a86d5C1a021f5DB";
  // const multisigWallet = "0x33c8E7Ae7435c9A82B5F26EDDc8bf23D3E113031";

  const Me3Token = await ethers.getContractFactory("Me3Token");
  const me3Token = await Me3Token.deploy("Me3 Token", "ME3", "1000000000000000000000000000");
  await me3Token.deployed();
  console.log(`me3Token  Deployed: ${me3Token.address}`);
  // await me3Token.transferOwnership(multisigWallet);
  // console.log(`me3Token's owner has been transferred to multisig: ${multisigWallet}`);

  // const TimeLock = await ethers.getContractFactory("Timelock");
  // const timeLock = await TimeLock.deploy(admin, "259200");
  // await timeLock.deployed();
  // console.log(`timeLock  Deployed: ${timeLock.address}`);

  // const Me3Governor = await ethers.getContractFactory("Governor");
  // const me3Governor = await Me3Governor.deploy(timeLock.address, me3Token.address, admin);
  // await me3Governor.deployed();
  // console.log(`me3Governor  Deployed: ${me3Governor.address}`);

  // const Me3Storage = await ethers.getContractFactory("Me3Storage");
  // const me3Storage = await Me3Storage.deploy();
  // await me3Storage.deployed();
  // console.log(`me3Storage  Deployed: ${me3Storage.address}`);
  // await me3Storage.transferStorageOwnership(multisigWallet);
  // console.log(`me3Storage's owner has been transferred to multisig: ${multisigWallet}`);

  // const Me3Farm = await ethers.getContractFactory("Me3Farm");
  // const me3Farm = await Me3Farm.deploy(me3Storage.address, me3Token.address);
  // await me3Farm.deployed();
  // console.log(`me3Farm  Deployed: ${me3Farm.address}`);

  if (hre.network.name === "mainnet" || hre.network.name === "goerli" || hre.network.name === "rinkeby") {
    await hre.run("verify:verify", {
      address: me3Token.address,
      constructorArguments: ["Me3 Token", "ME3", "1000000000000000000000000000"],
    });
    // await hre.run("verify:verify", {
    //   address: timeLock.address,
    //   constructorArguments: [admin, "259200"],
    // });
    // await hre.run("verify:verify", {
    //   address: me3Governor.address,
    //   constructorArguments: [timeLock.address, me3Token.address, admin],
    // });
    // await hre.run("verify:verify", {
    //   address: me3Storage.address,
    //   constructorArguments: [],
    // });
    // await hre.run("verify:verify", {
    //   address: me3Farm.address,
    //   constructorArguments: [me3Storage.address, me3Token.address],
    // });
  } else {
    console.log("Contracts deployed to", hre.network.name, "network. Please verify them manually.");
  }
}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
