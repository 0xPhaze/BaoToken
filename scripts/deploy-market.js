// const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
  // const BaoToken = await ethers.getContractFactory("BaoToken");
  // const token = BaoToken.attach("0x51D7e3713Dc5eB06974A93C1F755724fece53540");

  const BaoToken = await ethers.getContractFactory("MockERC20");
  const token = await BaoToken.deploy();

  const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = await Marketplace.deploy(token.address);

  console.log(`baoToken: "${token.address}",`);
  console.log(`marketplace: "${marketplace.address}",`);

  console.log(`npx hardhat verify ${token.address} --network ${hre.network.name}`);
  console.log(`npx hardhat verify ${marketplace.address} ${token.address} --network ${hre.network.name}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
