const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const admin = await ethers.getSigner();

  const AvartaToken = await ethers.getContractFactory("AvartaToken");
  const avartaToken = await AvartaToken.deploy("Avarta Token", "AVT", "1000000000000000000000000000");
  await avartaToken.deployed();
  console.log(`avartaToken  Deployed: ${avartaToken.address}`);

  const TimeLock = await ethers.getContractFactory("Timelock");
  const timeLock = await TimeLock.deploy(admin, "3 days");
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

  const AvartaFarm = await ethers.getContractFactory("AvartaFarm");
  const avartaFarm = await AvartaFarm.deploy(avartaStorage.address, avartaToken.address);
  await avartaFarm.deployed();
  console.log(`avartaFarm  Deployed: ${avartaFarm.address}`);

  if (hre.network.name === "mainnet" || hre.network.name === "testnet") {
    await hre.run("verify:verify", {
      address: avartaToken.address,
      constructorArguments: ["Avarta Token", "AVT", "1000000000000000000000000000"],
    });
    await hre.run("verify:verify", {
      address: timeLock.address,
      constructorArguments: [admin.address, "3 days"],
    });
    await hre.run("verify:verify", {
      address: avartaGovernor.address,
      constructorArguments: [timeLock.address, avartaToken.address, admin.address],
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
