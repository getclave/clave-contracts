# Clave ZkSync Contracts

## Project structure

-   `/contracts`: smart contracts.
-   `/deploy`: deployment and contract interaction scripts.
-   `/test`: test files.
-   `hardhat.config.ts`: configuration file.

## Requirements

-   run `cargo install --git https://github.com/matter-labs/era-test-node.git --locked` to install the zksync era test node.

## Commands

-   `npx hardhat compile` will compile the contracts, typescript bindings are generated automatically.
-   `npm run {filename}` will execute the script `/deploy/{filename}.ts`. Requires [environment variable setup](#environment-variables).
-   `npm run test`: run tests. **Requires a running zksync era test node.**
-   `npm run auto-test`: run tests without requiring running zksync era test node. **Download zksync era test node if you haven't.**
-   `npm run gas-report`: run tests and generate gas report. **Download zksync era test node if you haven't.**

### Environment variables

In order to prevent users to leak private keys, this project includes the `dotenv` package which is used to load environment variables. It's used to load the wallet private key, required to run the deploy script.

To use it, rename `.env.example` to `.env` and enter your private key.

```
PRIVATE_KEY=123cde574ccff....
```

## Official Links

-   [Website](https://getclave.io/)
-   [GitHub](https://github.com/getclave)
-   [Twitter](https://twitter.com/getclave)
