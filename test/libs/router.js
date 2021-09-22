const chalk = require("chalk")
const { getLPAddress } = require("./pair")
const { log } = require("./utils")

async function addLiquidityETH(
  routerContract,
  { token, tokenAmount, senderAddress, ethAmount }
) {
    await routerContract
        .addLiquidityETH(
            token.address,
            tokenAmount,
            0,
            0,
            senderAddress,
            new Date().getTime() + 60 * 1e3,
            { value: ethAmount }
        )
        .then(({ wait }) => wait())
    const symbol = await token.symbol()

    log(
        "Added liquidity:",
        chalk.greenBright(
            `${ethers.utils.formatEther(ethAmount)} ETH / ${ethers.utils.formatEther(
                tokenAmount
            )} ${symbol}`
        )
    )
}

async function addLiquidity(
    routerContract,
    { tokenA, tokenB, tokenAmountA, tokenAmountB, senderAddress }
) {
    const decimalsA = await tokenA.decimals()
    const symbolA = await tokenA.symbol()
    const balanceA = ethers.utils.formatUnits(tokenAmountA, decimalsA)

    const decimalsB = await tokenB.decimals()
    const symbolB = await tokenB.symbol()
    const balanceB = ethers.utils.formatUnits(tokenAmountB, decimalsB)

    await routerContract
        .addLiquidity(
        tokenA.address,
        tokenB.address,
        tokenAmountA,
        tokenAmountB,
        tokenAmountA,
        tokenAmountB,
        senderAddress,
        new Date().getTime() + 60 * 1e3
        )
        .then(({ wait }) => wait())

    log(
        "Added liquidity:",
        chalk.greenBright(`${balanceA} ${symbolA} / ${balanceB} ${symbolB}`)
    )
}

function swapExactETHForTokens(routerContract, { amountEth, path, to }) {
    return routerContract.swapExactETHForTokens(
        0,
        path,
        to,
        new Date().getTime() + 60 * 1e3,
        { value: amountEth }
    )
}

function swapExactTokensForETH(routerContract, { amountToken, path, to }) {
    return routerContract.swapExactTokensForETH(
        amountToken,
        0,
        path,
        to,
        new Date().getTime() + 60 * 1e3
    )
}

async function calculateSwapAmount(tokenA, tokenB, targetPrice) {
    // Default pancakeswap fee: 0.25%
    const feeRate = ethers.utils.parseEther("100025")

    const [reserveA, reserveB] = await getReserves(tokenA, tokenB)
    const swappedReserveA = sqrt(
        reserveA
        .mul(reserveB)
        .mul(targetPrice)
        .mul(feeRate)
        .div(ethers.utils.parseEther("100000"))
    )
    return swappedReserveA.sub(reserveA)
}

async function getReserves(tokenA, tokenB) {
    const lpAddress = await getLPAddress(tokenA.address, tokenB.address)
    const PancakePair = await ethers.getContractFactory("PancakePair")
    const pair = PancakePair.attach(lpAddress)
    const token0 = await pair.token0()
    if (token0.toLowerCase() === tokenA.address.toLowerCase()) {
        return pair.getReserves()
    } else {
        const _reserves = await pair.getReserves()
        return [_reserves[1], _reserves[0]]
    }
}

function sqrt(value) {
    const ONE = ethers.BigNumber.from(1)
    const TWO = ethers.BigNumber.from(2)
    x = ethers.BigNumber.from(value)
    let z = x.add(ONE).div(TWO)
    let y = x
    while (z.sub(y).isNegative()) {
        y = z
        z = x.div(z).add(z).div(TWO)
    }
    return y
}

module.exports = {
  addLiquidity,
  addLiquidityETH,
  calculateSwapAmount,
  getReserves,
  swapExactETHForTokens,
  swapExactTokensForETH
}