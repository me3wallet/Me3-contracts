const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const admin = "0xc2C320Eadf2D45bf5acE2f78271385878F7737ae";
  const multisigWallet = "0xf28EC1C0d93D86f1c4b8A725d2e821Db5411a16b";

  const AvartaToken = await ethers.getContractFactory("AvartaToken");
  const avartaToken = await AvartaToken.deploy("Avarta Token", "AVT", "1000000000000000000000000000");
  await avartaToken.deployed();
  console.log(`avartaToken  Deployed: ${avartaToken.address}`);
  await avartaToken.transferOwnership(multisigWallet);
  console.log(`avartaToken's owner has been transferred to multisig: ${multisigWallet}`);

  const TimeLock = await ethers.getContractFactory("Timelock");
  const timeLock = await TimeLock.deploy(admin, "259200");
  await timeLock.deployed();
  console.log(`timeLock  Deployed: ${timeLock.address}`);

  const AvartaGovernor = await ethers.getContractFactory("Governor");
  const avartaGovernor = await AvartaGovernor.deploy(timeLock.address, avartaToken.address, admin);
  await avartaGovernor.deployed();
  console.log(`avartaGovernor  Deployed: ${avartaGovernor.address}`);

  const AvartaStorage = await ethers.getContractFactory("AvartaStorage");
  const avartaStorage = await AvartaStorage.deploy();
  await avartaStorage.deployed();
  console.log(`avartaStorage  Deployed: ${avartaStorage.address}`);
  await avartaStorage.transferStorageOwnership(multisigWallet);
  console.log(`avartaStorage's owner has been transferred to multisig: ${multisigWallet}`);

  const AvartaFarm = await ethers.getContractFactory("AvartaFarm");
  const avartaFarm = await AvartaFarm.deploy(avartaStorage.address, avartaToken.address);
  await avartaFarm.deployed();
  console.log(`avartaFarm  Deployed: ${avartaFarm.address}`);

  if (hre.network.name === "mainnet" || hre.network.name === "testnet" || hre.network.name === "rinkeby") {
    await hre.run("verify:verify", {
      address: avartaToken.address,
      constructorArguments: ["Avarta Token", "AVT", "1000000000000000000000000000"],
    });
    await hre.run("verify:verify", {
      address: timeLock.address,
      constructorArguments: [admin, "259200"],
    });
    await hre.run("verify:verify", {
      address: avartaGovernor.address,
      constructorArguments: [timeLock.address, avartaToken.address, admin],
    });
    await hre.run("verify:verify", {
      address: avartaStorage.address,
      constructorArguments: [],
    });
    await hre.run("verify:verify", {
      address: avartaFarm.address,
      constructorArguments: [avartaStorage.address, avartaToken.address],
    });
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
