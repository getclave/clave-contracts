/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Contract } from '@ethersproject/contracts';
import { JsonRpcProvider } from '@ethersproject/providers';
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import { ethers } from 'ethers';
import * as hre from 'hardhat';
import type { Wallet } from 'zksync-ethers';
import { utils } from 'zksync-ethers';

import type {
    AccountFactory,
    BatchCaller,
    ClaveImplementation,
    ClaveRegistry,
    EOAValidator,
    MockExecutionHook,
    MockImplementation,
    MockModule,
    MockStable,
    MockValidationHook,
    MockValidator,
    P256VerifierExpensive,
    SocialRecoveryModule,
    TEEValidator,
} from '../../typechain-types';
import type { CallableProxy } from './proxy-helpers';

export async function deployBatchCaller(wallet: Wallet): Promise<BatchCaller> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const batchCallerArtifact = await deployer.loadArtifact('BatchCaller');

    const batchCaller = await deployer.deploy(
        batchCallerArtifact,
        [],
        undefined,
        [],
    );

    return await hre.ethers.getContractAt(
        'BatchCaller',
        await batchCaller.getAddress(),
        wallet,
    );
}

export async function deployImplementation(
    wallet: Wallet,
    batchCallerAddress: string,
): Promise<ClaveImplementation> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const claveImplArtifact = await deployer.loadArtifact(
        'ClaveImplementation',
    );

    const implementation = await deployer.deploy(
        claveImplArtifact,
        [batchCallerAddress],
        undefined,
        [],
    );

    return await hre.ethers.getContractAt(
        'ClaveImplementation',
        await implementation.getAddress(),
        wallet,
    );
}

export async function deployMockImplementation(
    wallet: Wallet,
): Promise<MockImplementation> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const mockImplArtifact = await deployer.loadArtifact('MockImplementation');

    const implementation = await deployer.deploy(
        mockImplArtifact,
        [],
        undefined,
        [],
    );

    return await hre.ethers.getContractAt(
        'MockImplementation',
        await implementation.getAddress(),
        wallet,
    );
}

export async function deployVerifier(
    wallet: Wallet,
): Promise<P256VerifierExpensive> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const verifierArtifact = await deployer.loadArtifact(
        'P256VerifierExpensive',
    );

    const verifier = await deployer.deploy(verifierArtifact, [], undefined, []);

    return await hre.ethers.getContractAt(
        'P256VerifierExpensive',
        await verifier.getAddress(),
        wallet,
    );
}

export async function deployMockValidator(
    wallet: Wallet,
): Promise<MockValidator> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const mockValidatorArtifact = await deployer.loadArtifact('MockValidator');

    const mockValidator = await deployer.deploy(
        mockValidatorArtifact,
        [],
        undefined,
        [],
    );

    return await hre.ethers.getContractAt(
        'MockValidator',
        await mockValidator.getAddress(),
        wallet,
    );
}

export async function deployTeeValidator(
    wallet: Wallet,
    verifierAddress: string,
): Promise<TEEValidator> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const teeValidatorArtifact = await deployer.loadArtifact('TEEValidator');

    const TEEValidator = await deployer.deploy(
        teeValidatorArtifact,
        [verifierAddress],
        undefined,
        [],
    );

    return await hre.ethers.getContractAt(
        'TEEValidator',
        await TEEValidator.getAddress(),
        wallet,
    );
}

export async function deployEOAValidator(
    wallet: Wallet,
): Promise<EOAValidator> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const eoaValidatorArtifact = await deployer.loadArtifact('EOAValidator');

    const eoaValidator = await deployer.deploy(
        eoaValidatorArtifact,
        [],
        undefined,
        [],
    );

    return await hre.ethers.getContractAt(
        'EOAValidator',
        await eoaValidator.getAddress(),
        wallet,
    );
}

export async function deploySocialRecoveryModule(
    wallet: Wallet,
): Promise<SocialRecoveryModule> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const socialRecoveryModuleArtifact = await deployer.loadArtifact(
        'SocialRecoveryModule',
    );

    const socialRecoveryModule = await deployer.deploy(
        socialRecoveryModuleArtifact,
        ['srm', '1', 0, 0],
        undefined,
        [],
    );

    return await hre.ethers.getContractAt(
        'SocialRecoveryModule',
        await socialRecoveryModule.getAddress(),
        wallet,
    );
}

export async function deployMockModule(wallet: Wallet): Promise<MockModule> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const mockModuleArtifact = await deployer.loadArtifact('MockModule');

    const mockModule = await deployer.deploy(
        mockModuleArtifact,
        [],
        undefined,
        [],
    );

    return await hre.ethers.getContractAt(
        'MockModule',
        await mockModule.getAddress(),
        wallet,
    );
}

export async function deployMockValidationHook(
    wallet: Wallet,
): Promise<MockValidationHook> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const mockHookArtifact = await deployer.loadArtifact('MockValidationHook');

    const mockHook = await deployer.deploy(mockHookArtifact, [], undefined, []);

    return await hre.ethers.getContractAt(
        'MockValidationHook',
        await mockHook.getAddress(),
        wallet,
    );
}

export async function deployMockExecutionHook(
    wallet: Wallet,
): Promise<MockExecutionHook> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const mockHookArtifact = await deployer.loadArtifact('MockExecutionHook');

    const mockHook = await deployer.deploy(mockHookArtifact, [], undefined, []);

    return await hre.ethers.getContractAt(
        'MockExecutionHook',
        await mockHook.getAddress(),
        wallet,
    );
}

export async function deployRegistry(wallet: Wallet): Promise<ClaveRegistry> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const registryArtifact = await deployer.loadArtifact('ClaveRegistry');

    const registry = await deployer.deploy(registryArtifact, [], undefined, []);

    return await hre.ethers.getContractAt(
        'ClaveRegistry',
        await registry.getAddress(),
        wallet,
    );
}

export async function deployFactory(
    wallet: Wallet,
    implAddress: string,
    registryAddress: string,
): Promise<AccountFactory> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const factoryArtifact = await deployer.loadArtifact('AccountFactory');
    const accountArtifact = await deployer.loadArtifact('ClaveProxy');
    const bytecodeHash = utils.hashBytecode(accountArtifact.bytecode);

    const factory = await deployer.deploy(
        factoryArtifact,
        [implAddress, registryAddress, bytecodeHash, wallet.address],
        undefined,
        [accountArtifact.bytecode],
    );

    return await hre.ethers.getContractAt(
        'AccountFactory',
        await factory.getAddress(),
        wallet,
    );
}

export async function deployAccount(
    wallet: Wallet,
    nonce: number,
    accountFactory: AccountFactory,
    validatorAddress: string,
    initialR1Owner: string,
    modules: Array<ethers.BytesLike> = [],
): Promise<CallableProxy> {
    const salt = ethers.randomBytes(32);

    const abiCoder = ethers.AbiCoder.defaultAbiCoder();
    const initializer =
        '0x1c6f4ceb' +
        abiCoder
            .encode(
                ['bytes', 'address', 'bytes[]'],
                [initialR1Owner, validatorAddress, modules],
            )
            .slice(2);

    const tx = await accountFactory.deployAccount(salt, initializer, {
        gasLimit: 10_000_000,
        nonce,
    });
    await tx.wait();

    const accountAddress = await accountFactory.getAddressForSalt(salt);

    return await hre.ethers.getContractAt(
        'ClaveImplementation',
        accountAddress,
        wallet,
    );
}

export async function deployMockStable(wallet: Wallet): Promise<MockStable> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const stableArtifact = await deployer.loadArtifact('MockStable');

    const stable = await deployer.deploy(stableArtifact, [], undefined, []);

    return await hre.ethers.getContractAt(
        'MockStable',
        await stable.getAddress(),
        wallet,
    );
}

export async function deployGaslessPaymaster(
    wallet: Wallet,
    registryAddress: string,
    limit: number,
): Promise<Contract> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const paymasterArtifact = await deployer.loadArtifact('GaslessPaymaster');

    const paymaster = await deployer.deploy(
        paymasterArtifact,
        [registryAddress, limit],
        undefined,
        [],
    );

    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const provider = new JsonRpcProvider(hre.network.config.url);

    return new Contract(
        await paymaster.getAddress(),
        paymasterArtifact.abi,
        provider,
    );
}

export async function deployERC20Paymaster(
    wallet: Wallet,
    tokens: Array<{
        tokenAddress: string;
        decimals: number;
        priceMarkup: number;
    }>,
): Promise<Contract> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const paymasterArtifact = await deployer.loadArtifact('ERC20Paymaster');

    const paymaster = await deployer.deploy(
        paymasterArtifact,
        [tokens],
        undefined,
        [],
    );

    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const provider = new JsonRpcProvider(hre.network.config.url);

    return new Contract(
        await paymaster.getAddress(),
        paymasterArtifact.abi,
        provider,
    );
}

export async function deployERC20PaymasterMock(
    wallet: Wallet,
    tokens: Array<{
        tokenAddress: string;
        decimals: number;
        priceMarkup: number;
    }>,
): Promise<Contract> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const paymasterArtifact = await deployer.loadArtifact('ERC20PaymasterMock');

    const paymaster = await deployer.deploy(
        paymasterArtifact,
        [tokens],
        undefined,
        [],
    );

    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const provider = new JsonRpcProvider(hre.network.config.url);

    return new Contract(
        await paymaster.getAddress(),
        paymasterArtifact.abi,
        provider,
    );
}

export async function deploySubsidizerPaymaster(
    wallet: Wallet,
    tokens: Array<{
        tokenAddress: string;
        decimals: number;
        priceMarkup: number;
    }>,
    registryAddress: string,
): Promise<Contract> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const paymasterArtifact = await deployer.loadArtifact(
        'SubsidizerPaymaster',
    );

    const paymaster = await deployer.deploy(
        paymasterArtifact,
        [tokens, registryAddress],
        undefined,
        [],
    );

    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const provider = new JsonRpcProvider(hre.network.config.url);

    return new Contract(
        await paymaster.getAddress(),
        paymasterArtifact.abi,
        provider,
    );
}

export async function deploySubsidizerPaymasterMock(
    wallet: Wallet,
    tokens: Array<{
        tokenAddress: string;
        decimals: number;
        priceMarkup: number;
    }>,
    registryAddress: string,
): Promise<Contract> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const paymasterArtifact = await deployer.loadArtifact(
        'SubsidizerPaymasterMock',
    );

    const paymaster = await deployer.deploy(
        paymasterArtifact,
        [tokens, registryAddress],
        undefined,
        [],
    );

    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const provider = new JsonRpcProvider(hre.network.config.url);

    return new Contract(
        await paymaster.getAddress(),
        paymasterArtifact.abi,
        provider,
    );
}

export async function deployETHDenverPaymaster(
    wallet: Wallet,
    registryAddress: string,
    limit: number,
    token: string,
): Promise<Contract> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const paymasterArtifact = await deployer.loadArtifact('ETHDenverPaymaster');

    const paymaster = await deployer.deploy(
        paymasterArtifact,
        [registryAddress, limit, token],
        undefined,
        [],
    );

    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const provider = new JsonRpcProvider(hre.network.config.url);

    return new Contract(
        await paymaster.getAddress(),
        paymasterArtifact.abi,
        provider,
    );
}
