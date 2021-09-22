const { ethers } = require("hardhat")
const { pack, keccak256 } = require("@ethersproject/solidity")
const { getCreate2Address } = require("@ethersproject/address")

async function getLPAddress(tokenA, tokenB) {
    const tokens =
        tokenA.toLowerCase() < tokenB.toLowerCase()
        ? [tokenA, tokenB]
        : [tokenB, tokenA]
    const initCodeHash = await global.pancakeFactory.INIT_CODE_PAIR_HASH()

    return getCreate2Address(
        global.pancakeFactory.address,
        keccak256(
            ["bytes"],
            [pack(["address", "address"], [tokens[0].toLowerCase(), tokens[1].toLowerCase()])]
        ),
        initCodeHash
    ).toLowerCase()
}

async function balanceOfLP(tokenA, tokenB, address){
    const lpAddress = await getLPAddress(tokenA.address, tokenB.address)
    const Pair = await ethers.getContractFactory("PancakePair")
    const pair = await Pair.attach(lpAddress)
    return pair.balanceOf(address)
}

module.exports = {
    balanceOfLP,
    getLPAddress
}