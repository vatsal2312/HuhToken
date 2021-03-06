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

_An individual with an approved wallet address makes a purchase of HUH tokens, the Referrer benefits by receiving a 7% redistribution of BNB on the initial purchase of the Referee. Both the Referrer and Referee receive a permanent reduced sell tax from n% to n% when they sell their HUH tokens._

_Should the Referee then refer a further individual in order to also benefit from this programme, the initial person in the chain also receives a n% reward from the purchase of the third person referred. This is capped at the third individual._

## Fees

![Fees](https://user-images.githubusercontent.com/16293599/133937617-66ac33e5-b129-4c34-92cd-f3639794519a.png)

All rewards are automatically re-distributed to all HUH token holders&#39; wallets in proportion to the amount of HUH held. There are no further actions required. A minimum of n HUH tokens have to be held to receive the distribution.

We will be using TikiToken&#39;s contract and modify it to our needs.

https://www.tikitoken.finance/whitepaper

## Dashboard

A dashboard that tracks the users BNB earnings when they provide their wallet address. Like TikiTokens dashboard [https://tikitoken.app/dashboard](https://tikitoken.app/dashboard)

The dashboard also has to track every successful referral a user has made and how much BNB they have made from those referrals.

A successful referral is someone that has &quot;approved&quot; their wallet address and then bought HUH tokens from pancake swap.
