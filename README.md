# Deflationary Reflection Referral Token

## Hardhat basic scripts

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```

## Token

We are making a dynamic smart contract that will act differently based on which wallet address interacts with it.

Users should be able to put their wallet address onto our website and generate a unique referral code for them.

This referral code can then be shared to other users.

Users should be able to put in their wallet address and a referral code they received from someone else to get their wallet address &quot;approved&quot;. This is done on the website.

If an **unapproved** wallet buys the token from pancake swap the contract will let it buy and sell normally.

If an **approved** wallet buys the token from pancake swap the contract will let it buy and sell with a lower % tax from n% tax on a sell lowered to a n% tax on sell. Also, on the 1st initial purchase of the token, n% BNB of that purchase goes directly to the persons wallet that referred the buyer.

Should the Referee then refer a further individual in order to also benefit from this programme, the initial person in the chain also receives a n% reward from the purchase of the third person referred. This is capped at the third individual.

**Scenario** :

_An individual with an approved wallet address makes a purchase of REFF tokens, the Referrer benefits by receiving a 7% redistribution of BNB on the initial purchase of the Referee. Both the Referrer and Referee receive a permanent reduced sell tax from n% to n% when they sell their REFF tokens._

_Should the Referee then refer a further individual in order to also benefit from this programme, the initial person in the chain also receives a n% reward from the purchase of the third person referred. This is capped at the third individual._

## Token info

The charge for making transaction is n% for purchases &amp; transfers, and n% for sales, this is on every transaction and is as follows:

## Buys

Normal buy tax:

10% BNB, 2% LP, 2% redistribution, 1% main wallet = 15%

## Whitelisted buys

For 1st transaction only:

- 10% BNB (first), 2% BNB (second), 1% LP, 1% redistribution, 1% main wallet = 15%

All whitelisted wallets go back to having a normal buy tax.

## Sells

10% BNB, 4% LP, 4% redistribution, 2% main wallet = 20%

## Whitelisted sell

For 1st transaction only:

- 5% BNB, 2% LP, 2% redistribution, 1% main wallet = 10%

After 1st transaction:

- 5% BNB, 2% LP, 2% redistribution, 1%main wallet = 10%

Once a wallet is whitelisted, they get permanent reduced sell tax

All rewards are automatically re-distributed to all REFF token holders&#39; wallets in proportion to the amount of REFF held. There are no further actions required. A minimum of n REFF tokens have to be held to receive the distribution.

We will be using TikiToken&#39;s contract and modify it to our needs.

https://www.tikitoken.finance/whitepaper

## Dashboard

A dashboard that tracks the users BNB earnings when they provide their wallet address. Like TikiTokens dashboard [https://tikitoken.app/dashboard](https://tikitoken.app/dashboard)

The dashboard also has to track every successful referral a user has made and how much BNB they have made from those referrals.

A successful referral is someone that has &quot;approved&quot; their wallet address and then bought REFF tokens from pancake swap.