const { expect } = require("chai")
const { ethers } = require("hardhat")
const { setupTests } = require("./setup")
const { getLPAddress } = require("./libs/pair")
const { approveTokens } = require("./libs/token")
const {
    addLiquidity,
    addLiquidityETH,
    swapExactTokensForETH,
    getReserves,
    calculateSwapAmount,
    swapExactETHForTokens
} = require("./libs/router")
const parseEther = ethers.utils.parseEther;

describe("HuhToken", async () => {
    let owner, user1, user2, user3, user4, huh, weth, busd;

    before(async () => {
        global.showLog = false
        await setupTests()

        huh = global.huh
        weth = global.weth
        busd = global.busd
        pancakeRouter = global.pancakeRouter
        owner = global.users[0]
        user1 = global.users[1]
        user2 = global.users[2]
        user3 = global.users[3]
        user4 = global.users[4]
    })

    describe('Initial checks', async () => {
        it('Check token details', async () => {
            expect(await huh.balanceOf(owner.address)).to.be.eq(parseEther('999999999980000')) // 1 Quadrillion - 10k (LP)
            expect(await huh.totalSupply()).to.be.eq(parseEther('1000000000000000'))
            expect(await huh.owner()).to.be.eq(owner.address)
            expect(await huh.name()).to.be.eq('HUH Token')
            expect(await huh.symbol()).to.be.eq('HUH')
        })

        it('Check liquidity', async () => {
            const wethHuhAddr = await getLPAddress(weth.address, huh.address)
            expect(await huh.balanceOf(wethHuhAddr)).to.be.eq(parseEther('10000'))

            const busdHuhAddr = await getLPAddress(busd.address, huh.address)
            expect(await huh.balanceOf(busdHuhAddr)).to.be.eq(parseEther('10000'))

            const [reserveA, reserveB] = await getReserves(huh, weth)
            expect(await reserveA.toString()).to.be.eq(parseEther('10000')) // 10k HUH
            expect(await reserveB.toString()).to.be.eq(parseEther('10')) // 10 ETH
        })
    })

    describe('Check swap and fees', async () => {
        it('Transfer tokens to another user (no fee)', async () => {
            await huh.connect(owner).transfer(user1.address, parseEther('500')) // -500 HUH
            expect(await huh.balanceOf(user1.address)).to.be.eq(parseEther('500'))
            expect(await huh.balanceOf(owner.address)).to.be.eq(parseEther('999999999979500'))
        })

        it('Non-whitelisted sell', async () => {
            await approveTokens([huh.connect(user1), busd.connect(user1)], pancakeRouter.address)
            await swapExactTokensForETH(pancakeRouter.connect(user1), {
                amountToken: parseEther('100'),
                path: [huh.address, weth.address],
                to: user1.address
            })
        })
    })
})

