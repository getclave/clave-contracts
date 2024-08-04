# Clave ZkSync Contracts

<img src="logo.svg" alt="Clave">

## Project structure

-   `/contracts`: smart contracts.
-   `/deploy`: deployment and contract interaction scripts.
-   `/test`: test files
-   `hardhat.config.ts`: configuration file.

## Commands

-   `npx hardhat compile` will compile the contracts, typescript bindings are generated automatically.
-   `npx hardhat deploy {contract name} {constructor arguments}` will deploy and verify the contract. Requires [environment variable setup](#environment-variables).
-   `npm run test`: run tests.

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
