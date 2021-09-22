const chalk = require("chalk")

function printContractAddress(contracts) {
    contracts.forEach(({ contract, name }) => {
        log(`Deployed ${name}:`, chalk.greenBright(contract.address))
    })
}

function log(message, ...params) {
    if (global.showLog) {
        console.log(message, ...params)
    }
}
module.exports = {
    printContractAddress,
    log
}
