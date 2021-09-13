const { ethers } = require('hardhat')
const hre = require("hardhat");

async function main() {
    const HuhToken = await ethers.getContractFactory("HUH");

    const huhToken = await HuhToken.deploy();
    console.log("HUH token deployed to:", huhToken.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
