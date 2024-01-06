/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import { ethers } from 'ethers';
import * as hre from 'hardhat';
import type { Wallet } from 'zksync-web3';
import { utils } from 'zksync-web3';

import type {
    AccountFactory,
    BatchCaller,
    ClaveImplementation,
    ClaveRegistry,
    EOAValidator,
    ERC20Paymaster,
    ERC20PaymasterMock,
    GaslessPaymaster,
    MockExecutionHook,
    MockImplementation,
    MockModule,
    MockStable,
    MockValidationHook,
    MockValidator,
    P256VerifierExpensive,
    SocialRecoveryModule,
    SubsidizerPaymaster,
    SubsidizerPaymasterMock,
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
        batchCaller.address,
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
        implementation.address,
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
        implementation.address,
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
        verifier.address,
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
        mockValidator.address,
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
        TEEValidator.address,
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
        eoaValidator.address,
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
        socialRecoveryModule.address,
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
        mockModule.address,
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
        mockHook.address,
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
        mockHook.address,
        wallet,
    );
}

export async function deployRegistry(wallet: Wallet): Promise<ClaveRegistry> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const registryArtifact = await deployer.loadArtifact('ClaveRegistry');

    const registry = await deployer.deploy(registryArtifact, [], undefined, []);

    return await hre.ethers.getContractAt(
        'ClaveRegistry',
        registry.address,
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
        factory.address,
        wallet,
    );
}

export async function deployAccount(
    wallet: Wallet,
    accountFactory: AccountFactory,
    validatorAddress: string,
    initialR1Owner: string,
    modules: Array<ethers.BytesLike> = [],
): Promise<CallableProxy> {
    const salt = ethers.utils.randomBytes(32);

    const abiCoder = ethers.utils.defaultAbiCoder;
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

    return await hre.ethers.getContractAt('MockStable', stable.address, wallet);
}

export async function deployGaslessPaymaster(
    wallet: Wallet,
    registryAddress: string,
    limit: number,
): Promise<GaslessPaymaster> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const paymasterArtifact = await deployer.loadArtifact('GaslessPaymaster');

    const paymaster = await deployer.deploy(
        paymasterArtifact,
        [registryAddress, limit],
        undefined,
        [],
    );

    return await hre.ethers.getContractAt(
        'GaslessPaymaster',
        paymaster.address,
        wallet,
    );
}

export async function deployERC20Paymaster(
    wallet: Wallet,
    tokens: Array<{
        tokenAddress: string;
        decimals: number;
        priceMarkup: number;
    }>,
): Promise<ERC20Paymaster> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const paymasterArtifact = await deployer.loadArtifact('ERC20Paymaster');

    const paymaster = await deployer.deploy(
        paymasterArtifact,
        [tokens],
        undefined,
        [],
    );

    return await hre.ethers.getContractAt(
        'ERC20Paymaster',
        paymaster.address,
        wallet,
    );
}

export async function deployERC20PaymasterMock(
    wallet: Wallet,
    tokens: Array<{
        tokenAddress: string;
        decimals: number;
        priceMarkup: number;
    }>,
): Promise<ERC20PaymasterMock> {
    const deployer: Deployer = new Deployer(hre, wallet);
    const paymasterArtifact = await deployer.loadArtifact('ERC20PaymasterMock');

    const paymaster = await deployer.deploy(
        paymasterArtifact,
        [tokens],
        undefined,
        [],
    );

    return await hre.ethers.getContractAt(
        'ERC20PaymasterMock',
        paymaster.address,
        wallet,
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
): Promise<SubsidizerPaymaster> {
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

    return await hre.ethers.getContractAt(
        'SubsidizerPaymaster',
        paymaster.address,
        wallet,
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
): Promise<SubsidizerPaymasterMock> {
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

    return await hre.ethers.getContractAt(
        'SubsidizerPaymasterMock',
        paymaster.address,
        wallet,
    );
}
