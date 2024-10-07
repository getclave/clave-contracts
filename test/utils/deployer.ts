/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ec } from 'elliptic';
import { AbiCoder, ZeroAddress, parseEther, randomBytes } from 'ethers';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import type { Wallet } from 'zksync-ethers';
import { Contract, utils } from 'zksync-ethers';

import { deployContract, getWallet } from '../../deploy/utils';
import type { CallStruct } from '../../typechain-types/contracts/batch/BatchCaller';
import { CONTRACT_NAMES, PAYMASTERS, type VALIDATORS } from './names';
import { encodePublicKey } from './p256';

// This class helps deploy Clave contracts for the tests
export class ClaveDeployer {
    private hre: HardhatRuntimeEnvironment;
    private deployerWallet: Wallet;

    constructor(
        hre: HardhatRuntimeEnvironment,
        deployerWallet: string | Wallet,
    ) {
        this.hre = hre;

        typeof deployerWallet === 'string'
            ? (this.deployerWallet = getWallet(this.hre, deployerWallet))
            : (this.deployerWallet = deployerWallet);
    }

    public async batchCaller(): Promise<Contract> {
        return await deployContract(
            this.hre,
            CONTRACT_NAMES.BATCH_CALLER,
            undefined,
            {
                wallet: this.deployerWallet,
                silent: true,
            },
        );
    }

    public async registry(): Promise<Contract> {
        return await deployContract(
            this.hre,
            CONTRACT_NAMES.REGISTRY,
            undefined,
            {
                wallet: this.deployerWallet,
                silent: true,
            },
        );
    }

    public async implementation(batchCaller: Contract): Promise<Contract> {
        return await deployContract(
            this.hre,
            CONTRACT_NAMES.IMPLEMENTATION,
            [await batchCaller.getAddress()],
            {
                wallet: this.deployerWallet,
                silent: true,
            },
        );
    }

    public async factory(
        implementation: Contract,
        registry: Contract,
    ): Promise<Contract> {
        // TODO: WHY DOES THIS HELP
        await deployContract(
            this.hre,
            CONTRACT_NAMES.PROXY,
            [await implementation.getAddress()],
            { wallet: this.deployerWallet, silent: true },
        );

        // Deploy factory contract
        const accountArtifact = await this.hre.zksyncEthers.loadArtifact(
            CONTRACT_NAMES.PROXY,
        );
        const bytecodeHash = utils.hashBytecode(accountArtifact.bytecode);
        const factory = await deployContract(
            this.hre,
            CONTRACT_NAMES.FACTORY,
            [
                await implementation.getAddress(),
                await registry.getAddress(),
                bytecodeHash,
                this.deployerWallet.address,
            ],
            {
                wallet: this.deployerWallet,
                silent: true,
            },
        );

        // Assign the factory address to the registry
        const factorySetTx = await registry.setFactory(
            await factory.getAddress(),
        );
        await factorySetTx.wait();

        return factory;
    }

    public async setupFactory(): Promise<{
        batchCaller: Contract;
        registry: Contract;
        implementation: Contract;
        factory: Contract;
    }> {
        const batchCaller = await this.batchCaller();
        const registry = await this.registry();
        const implementation = await this.implementation(batchCaller);
        const factory = await this.factory(implementation, registry);

        return { batchCaller, registry, implementation, factory };
    }

    public async validator(name: VALIDATORS): Promise<Contract> {
        return await deployContract(this.hre, name, undefined, {
            wallet: this.deployerWallet,
            silent: true,
        });
    }

    public async account(
        keyPair: ec.KeyPair,
        factory: Contract,
        validator: Contract,
    ): Promise<Contract> {
        const publicKey = encodePublicKey(keyPair);

        const salt = randomBytes(32);
        const call: CallStruct = {
            target: ZeroAddress,
            allowFailure: false,
            value: 0,
            callData: '0x',
        };

        const abiCoder = AbiCoder.defaultAbiCoder();
        const initializer =
            '0x77ba2e75' +
            abiCoder
                .encode(
                    [
                        'bytes',
                        'address',
                        'bytes[]',
                        'tuple(address target,bool allowFailure,uint256 value,bytes calldata)',
                    ],
                    [
                        publicKey,
                        await validator.getAddress(),
                        [],
                        [
                            call.target,
                            call.allowFailure,
                            call.value,
                            call.callData,
                        ],
                    ],
                )
                .slice(2);

        const deployPromise = await Promise.all([
            // Deploy account
            (async (): Promise<void> => {
                const deployTx = await factory.deployAccount(salt, initializer);
                await deployTx.wait();
            })(),
            // Calculate  new account address
            (async (): Promise<string> => {
                return await factory.getAddressForSalt(salt);
            })(),
        ]);

        const accountAddress = deployPromise[1];
        const implementationInterface = (
            await this.hre.zksyncEthers.loadArtifact(
                CONTRACT_NAMES.IMPLEMENTATION,
            )
        ).abi;

        const account = new Contract(
            accountAddress,
            implementationInterface,
            this.deployerWallet,
        );

        return account;
    }

    public async paymaster(
        name: PAYMASTERS,
        config: {
            gasless?: [registryAddress: string, limit: number];
            erc20?: Array<{
                tokenAddress: string;
                decimals: number;
                priceMarkup: number;
            }>;
        },
    ): Promise<Contract> {
        if (
            (name === PAYMASTERS.GASLESS && !config.gasless) ||
            (name === PAYMASTERS.ERC20 && !config.erc20) ||
            (name === PAYMASTERS.ERC20_MOCK && !config.erc20)
        ) {
            throw new Error('Config mismatch.');
        }

        return await deployContract(
            this.hre,
            name,
            name == PAYMASTERS.GASLESS ? config.gasless : [config.erc20],
            {
                wallet: this.deployerWallet,
                silent: true,
            },
        );
    }

    public async fund(
        ethAmount: number,
        accountAddress: string,
    ): Promise<void> {
        await (
            await this.deployerWallet.sendTransaction({
                to: accountAddress,
                value: parseEther(ethAmount.toString()),
            })
        ).wait();
    }

    public async deployCustomContract(
        name: string,
        constructorArgs: Array<unknown>,
    ): Promise<Contract> {
        return await deployContract(this.hre, name, constructorArgs, {
            wallet: this.deployerWallet,
            silent: true,
        });
    }
}
