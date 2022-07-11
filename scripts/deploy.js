const { ethers } = require("hardhat");

const rarities = require("../rarities");

async function main() {
  // const owner = await ethers.getSigner();

  const BaoSociety = await ethers.getContractFactory("MockERC721A");
  const nft = await BaoSociety.deploy();

  const BaoToken = await ethers.getContractFactory("BaoToken");
  const token = await BaoToken.deploy(nft.address);

  const BaoProxy = await ethers.getContractFactory("BaoProxy");
  const proxy = await BaoProxy.deploy(token.address);

  // const Marketplace = await ethers.getContractFactory("Marketplace");
  // const marketplace = await Marketplace.deploy(token.address);

  console.log(`baoSociety: "${nft.address}",`);
  console.log(`baoToken: "${token.address}",`);
  console.log(`proxy: "${proxy.address}",`);
  // console.log(`marketplace: "${marketplace.address}",`);
  await token.deployed();

  await (await token.setRarities(rarities.ids.slice(0, 350), rarities.data.slice(0, 350))).wait();
  await (await token.setRarities(rarities.ids.slice(350, 700), rarities.data.slice(350, 700))).wait();
  await (await token.setRarities(rarities.ids.slice(700, 1050), rarities.data.slice(700, 1050))).wait();
  await (await token.setRarities(rarities.ids.slice(1050), rarities.data.slice(1050))).wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
