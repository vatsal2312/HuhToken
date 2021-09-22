const { ethers } = require("hardhat")
const { addLiquidity, addLiquidityETH } = require("./libs/router")
const { approveTokens, printBalance } = require("./libs/token")
const { printContractAddress } = require("./libs/utils")
const { log } = require("./libs/utils")

async function setupTests() {
  const users = await ethers.getSigners()
  const owner = users[0];
  const WETH = await ethers.getContractFactory("WETH")
  const PancakeFactory = await ethers.getContractFactory("PancakeFactory")
  const PancakeRouterV2 = await ethers.getContractFactory("PancakeRouter")
  const BUSD = await ethers.getContractFactory("BUSD")
  const HUH = await ethers.getContractFactory("HUH")

  const busd = await BUSD.deploy()
  const weth = await WETH.deploy()
  const pancakeFactory = await PancakeFactory.deploy(owner.address)

  await weth.deployed()
  await pancakeFactory.deployed()

  const pancakeRouter = await PancakeRouterV2.deploy(
    pancakeFactory.address,
    weth.address
  )
  await pancakeRouter.deployed()

  const huh = await HUH.deploy(pancakeRouter.address)
  await huh.deployed()

  printContractAddress([
    { contract: weth, name: "WETH" },
    { contract: busd, name: "BUSD" },
    { contract: huh, name: "HUH" },
    { contract: pancakeFactory, name: "PancakeFactory" },
    { contract: pancakeRouter, name: "PancakeRouter" }
  ])
  log("")

  // Approve huh and busd to pancake router.
  await approveTokens([huh, busd], pancakeRouter.address)
  log("")

  // Print huh and busd balance
  await printBalance([huh, busd], owner.address)

  // Add ETH/BUSD, ETH/HUH, and HUH/BUSD
  await addLiquidityETH(pancakeRouter, {
    token: busd,
    tokenAmount: ethers.utils.parseEther("10000"),
    senderAddress: owner.address,
    ethAmount: ethers.utils.parseEther("10")
  })

  await addLiquidityETH(pancakeRouter, {
    token: huh,
    tokenAmount: ethers.utils.parseEther("10000"),
    senderAddress: owner.address,
    ethAmount: ethers.utils.parseEther("10")
  })

  await addLiquidity(pancakeRouter, {
    tokenA: huh,
    tokenB: busd,
    tokenAmountA: ethers.utils.parseEther("10000"),
    tokenAmountB: ethers.utils.parseEther("10000"),
    senderAddress: owner.address
  })

  log("")


  global = {
    ...global,
    users,
    huh,
    busd,
    weth,
    pancakeRouter,
    pancakeFactory
  }
}

module.exports = {
  setupTests
}