const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const admin = "0x33c8E7Ae7435c9A82B5F26EDDc8bf23D3E113031";
  
  if (hre.network.name === "mainnet" || hre.network.name === "goerli" || hre.network.name === "rinkeby") {
    await hre.run("verify:verify", {
      address: "0x7Bbf825388E5992eeD09442eC633CAfd9e446C07",
      constructorArguments: ["Me3 Token", "ME3", "1000000000000000000000000000"],
    });
    // await hre.run("verify:verify", {
    //   address: "0xadbe7406F065b61236915Dc7Bc3Eba51f8d2d8fa",
    //   constructorArguments: [admin, "259200"],
    // });
    // await hre.run("verify:verify", {
    //   address: "0xE5677Cd57ee9437C2dA695091Ca36F981e0176D4",
    //   constructorArguments: ["0xadbe7406F065b61236915Dc7Bc3Eba51f8d2d8fa", "0x3f6B976D798947DbdDC4cf2d176b67f0E29246Fa", admin],
    // });
    // await hre.run("verify:verify", {
    //   address: "0x936934b92F23aa4b18bb7261226DD1deC54c26cf",
    //   constructorArguments: [],
    // });
    // await hre.run("verify:verify", {
    //   address: "0xEfd6Fd936f450C87061B53D77f4fB4b9cCcd990c",
    //   constructorArguments: ["0x936934b92F23aa4b18bb7261226DD1deC54c26cf", "0x3f6B976D798947DbdDC4cf2d176b67f0E29246Fa"],
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
