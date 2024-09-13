/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Contract } from 'ethers';
import * as hre from 'hardhat';

import { deployContract, getContractBytecodeHash, getWallet } from './utils';

/*
 * This is an MVP deploy script that handles deplopyment of the following modules:
 *
 * BatchCaller
 * ClaveImplementation
 * ClaveRegistry
 * GaslessPaymaster
 * ClaveProxy
 * PasskeyValidator
 * AccountFactory
 */
export default async function (): Promise<void> {
    const wallet = getWallet(hre);

    const deploymentConfig = {
        PAYMASTER_USER_LIMIT: 50,
        DEPLOYER_ADDRESS: wallet.address,
    };

    const batchCaller = await deployBatchCaller();
    const implementation = await deployImplementation(batchCaller);
    const registry = await deployRegistry();
    const gaslessPaymaster = await deployPaymaster(
        registry,
        deploymentConfig.PAYMASTER_USER_LIMIT,
    );
    const claveProxy = await deployClaveProxy(implementation);
    const passkeyValidator = await deployPasskeyValidator();
    const accountFactory = await deployFactory(
        implementation,
        registry,
        deploymentConfig.DEPLOYER_ADDRESS,
    );

    console.log({
        batchCaller,
        implementation,
        registry,
        gaslessPaymaster,
        claveProxy,
        passkeyValidator,
        accountFactory,
    });
}

const deployBatchCaller = async (): Promise<string> => {
    const contractArtifactName = 'BatchCaller';
    const result = await deployContract(hre, contractArtifactName, []);
    return await result.getAddress();
};

const deployImplementation = async (
    batchCallerAdddress: string,
): Promise<string> => {
    const contractArtifactName = 'ClaveImplementation';
    const result = await deployContract(hre, contractArtifactName, [
        batchCallerAdddress,
    ]);
    return await result.getAddress();
};

const deployRegistry = async (): Promise<string> => {
    const contractArtifactName = 'ClaveRegistry';
    const result = await deployContract(hre, contractArtifactName);
    return await result.getAddress();
};

const deployPaymaster = async (
    registryAddress: string,
    limit: number,
): Promise<string> => {
    const contractArtifactName = 'GaslessPaymaster';
    const result = await deployContract(hre, contractArtifactName, [
        registryAddress,
        limit,
    ]);
    return await result.getAddress();
};

const deployClaveProxy = async (
    implementationAddress: string,
): Promise<string> => {
    const contractArtifactName = 'ClaveProxy';
    const result = await deployContract(hre, contractArtifactName, [
        implementationAddress,
    ]);
    return await result.getAddress();
};

const deployPasskeyValidator = async (): Promise<string> => {
    const contractArtifactName = 'PasskeyValidator';
    const result = await deployContract(hre, contractArtifactName, []);
    return await result.getAddress();
};

const deployFactory = async (
    implementationAddress: string,
    registryAddress: string,
    deployer: string,
): Promise<string> => {
    const proxyArtifact = await hre.artifacts.readArtifact('ClaveProxy');
    const bytecode = proxyArtifact.bytecode;
    const bytecodeHash = getContractBytecodeHash(bytecode);

    const contractArtifactName = 'AccountFactory';
    const result = await deployContract(hre, contractArtifactName, [
        implementationAddress,
        registryAddress,
        bytecodeHash,
        deployer,
    ]);

    const registryArtifact = await hre.artifacts.readArtifact('ClaveRegistry');

    const registryContract = new Contract(
        registryAddress,
        registryArtifact.abi,
        getWallet(hre),
    );

    const accountFactoryAddress = await result.getAddress();

    console.log(`Setting factory address to ${accountFactoryAddress}`);
    await registryContract.setFactory(accountFactoryAddress);
    console.log('Successfully set factory address in registry contract');

    return accountFactoryAddress;
};
