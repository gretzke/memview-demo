# Memview Demo

[![License](https://img.shields.io/badge/License-AGPLv3-green.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![CI Status](https://github.com/gretzke/memview-demo/actions/workflows/tests.yml/badge.svg)](https://github.com/gretzke/memview-demo/actions)
[![Coverage Status](https://coveralls.io/repos/github/gretzke/memview-demo/badge.svg?branch=main&t=ZTUm69)](https://coveralls.io/github/gretzke/memview-demo?branch=main)

The Solidity library [MemView](https://github.com/summa-tx/memview-sol) is a very powerful tool for parsing and validating arbitrary data. The purpose of this repo is to demonstrate the use of MemView in a smart contract. The contracts are a POC of a bridge contract that accepts an arbitrary `bytes` payload and parses it to execute different kinds of transactions (e.g., ERC20 transfers, NFT transfers or arbitrary contract calls). The code also demonstrates nested MemViews, which are useful for parsing complex data structures. MemView also allows for very flexible data handling, making it easy to add more functionality through upgrades.

## Build and Test

On the project root, run:

```bash
$ npm i                 # install dependencies
$ npm run compile       # compile contracts and generate typechain
$ npm test              # run tests
```

optional:

```bash
$ npm run coverage      # run test coverage tool
```

To run foundry tests:

```bash
$ forge build           # compile contracts
$ forge test            # run foundry tests
```

## Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Goerli.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Infura API key, and the mnemonic phrase of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
npx hardhat run scripts/deploy.ts --network goerli
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network goerli DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```

# Performance optimizations

For faster runs of your tests and scripts, consider skipping ts-node's type checking by setting the environment variable `TS_NODE_TRANSPILE_ONLY` to `1` in hardhat's environment. For more details see [the documentation](https://hardhat.org/guides/typescript.html#performance-optimizations).
