const fs = require("fs");
const { ethers } = require("ethers");

// const t = require("../json/1.json");
// console.log(t);

var rarities = {};

let rs = 3872;

const lookup = {
  Plain: 5,
  Blush: 10,
  Ghost: 25,
  Rainbow: 50,
  "Yellow Jello": 75,
  Metal: 75,
  Gold: 100,
  Glass: 125,
  "1/1s": 250,
};

for (let i = 1; i < 3889; i++) {
  let metadataId = 1 + ((rs + i) % 3888);
  let attributes = require(`../json/${metadataId}.json`).attributes;
  let skin = attributes.filter(({ trait_type }) => trait_type === "Skin")[0].value;

  rarities[i] = lookup[skin] || 250;
}

let ids = Object.entries(rarities)
  .filter(([key, value]) => value !== 5)
  .map(([key]) => key);

let data = Object.entries(rarities)
  .filter(([key, value]) => value !== 5)
  .map(([_, value]) => value);

// console.log("writing to file");
fs.writeFileSync("rarities.js", "export default " + JSON.stringify({ ids, data }, null, 2), console.log);
