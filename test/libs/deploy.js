const { ethers } = require("hardhat")

async function deploy(contractName, constructorArgs = [], options = {}) {
  const Contract = await ethers.getContractFactory(contractName, options)
  const contract = await Contract.deploy(...constructorArgs)
  await contract.deployed()

  return contract
}

module.exports = {
  deploy
}