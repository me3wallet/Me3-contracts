const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const admin = "0xc2C320Eadf2D45bf5acE2f78271385878F7737ae";
  
  if (hre.network.name === "mainnet" || hre.network.name === "testnet" || hre.network.name === "rinkeby") {
    // await hre.run("verify:verify", {
    //   address: "0xdB8D064D8CCAb86fD065baE49Df1dfc9f32480DB",
    //   constructorArguments: ["Avarta Token", "AVT", "1000000000000000000000000000"],
    // });
    // await hre.run("verify:verify", {
    //   address: "0x0419C6D8Dd0Ee71B3511a9166a02DDb6aaC245EF",
    //   constructorArguments: [admin, "259200"],
    // });
    await hre.run("verify:verify", {
      address: "0xFbCFF14CfbAFc5f400E1843565A6e3CC832245b4",
      constructorArguments: ["0x0419C6D8Dd0Ee71B3511a9166a02DDb6aaC245EF", "0xdB8D064D8CCAb86fD065baE49Df1dfc9f32480DB", admin],
    });
    await hre.run("verify:verify", {
      address: "0x2C506F4f31B0CA121Ef4c0b9681B3A38d88995EB",
      constructorArguments: [],
    });
    await hre.run("verify:verify", {
      address: "0x9E70D71737e289a6b4a4d02A9CC2D42De02A8940",
      constructorArguments: ["0x2C506F4f31B0CA121Ef4c0b9681B3A38d88995EB", "0xdB8D064D8CCAb86fD065baE49Df1dfc9f32480DB"],
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
