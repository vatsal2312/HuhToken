const { ethers } = require("hardhat")
const chalk = require("chalk")
const { log } = require("./utils")

async function approveTokens(contracts, spender) {
    for (const contract of contracts) {
        const symbol = await contract.symbol()
        await contract
            .approve(spender, ethers.constants.MaxUint256)
            .then((tx) => tx.wait())
        log(`Approved ${symbol} to ${chalk.greenBright(spender)}`)
    }
}

async function printBalance(contracts, address) {
    for (const contract of contracts) {
        const symbol = await contract.symbol()
        const decimals = await contract.decimals()
        const _balance = await contract.balanceOf(address)
        const balance = ethers.utils.formatUnits(_balance, decimals)
        log(`${symbol} Balance:`, chalk.greenBright(balance))
    }
}

module.exports = {
    approveTokens,
    printBalance
}