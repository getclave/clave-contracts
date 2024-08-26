/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ec } from 'elliptic';
import {
    ZeroAddress,
    parseEther,
    zeroPadValue
} from 'ethers';
import * as hre from 'hardhat';
import { Contract, Provider, Wallet, utils } from 'zksync-ethers';
import { LOCAL_RICH_WALLETS, deployContract, getWallet, verifyContract } from '../deploy/utils';
import type { CallStruct } from '../typechain-types/contracts/batch/BatchCaller';
import { genKeyK1, encodePublicKeyK1 } from '../test/utils/p256';
let provider: Provider;
let fundingWallet: Wallet;
let keyPair: ec.KeyPair;

let batchCaller: Contract;
let eoaValidator: Contract;
let implementation: Contract;
let factory: Contract;
let account: Contract;
let registry: Contract;

// An example of a basic deploy script
// Do not push modifications to this file
// Just modify, interact then revert changes
export default async function (): Promise<void> {
    provider = new Provider(hre.network.config.url, undefined, {
        cacheTimeout: -1,
    });

    fundingWallet = getWallet(hre);

    keyPair = genKeyK1();
    const publicKey = encodePublicKeyK1(keyPair);

    console.log("authorized signer", publicKey);

    batchCaller = await deployContract(hre, 'BatchCaller', undefined, {
        wallet: fundingWallet,
        silent: true,
    });

    eoaValidator = await deployContract(hre, 'EOAValidator', undefined, {
        wallet: fundingWallet,
        silent: true,
    });

    implementation = await deployContract(
        hre,
        'ClaveImplementation',
        [await batchCaller.getAddress()],
        {
            wallet: fundingWallet,
            silent: true,
        },
    );

    registry = await deployContract(hre, 'ClaveRegistry', undefined, {
        wallet: fundingWallet,
        silent: true,
    });

    // //TODO: WHY DOES THIS HELP
    // await deployContract(
    //     hre,
    //     'ClaveProxy',
    //     [await implementation.getAddress()],
    //     { wallet: fundingWallet, silent: true },
    // );

    const accountProxyArtifact = await hre.zksyncEthers.loadArtifact('ClaveProxy');
    const bytecodeHash = utils.hashBytecode(accountProxyArtifact.bytecode);
    factory = await deployContract(
        hre,
        'AccountFactory',
        [
            await implementation.getAddress(),
            await registry.getAddress(),
            bytecodeHash,
            fundingWallet.address,
        ],
        {
            wallet: fundingWallet,
            silent: true,
        },
    );
    await registry.setFactory(await factory.getAddress());

    const salt = hre.ethers.randomBytes(32);
    const call: CallStruct = {
        target: ZeroAddress,
        allowFailure: false,
        value: 0,
        callData: '0x',
    };

    const abiCoder = hre.ethers.AbiCoder.defaultAbiCoder();
    const initializer =
        '0xb4e581f5' +
        abiCoder
            .encode(
                [
                    'address',
                    'address',
                    'bytes[]',
                    'tuple(address target,bool allowFailure,uint256 value,bytes calldata)',
                ],
                [
                    publicKey,
                    await eoaValidator.getAddress(),
                    [],
                    [call.target, call.allowFailure, call.value, call.callData],
                ],
            )
            .slice(2);

    const tx = await factory.deployAccount(salt, initializer);
    await tx.wait();

    const accountAddress = await factory.getAddressForSalt(salt);
    await verifyContract(hre, {
        address: accountAddress,
        contract: "contracts/ClaveProxy.sol:ClaveProxy",
        constructorArguments: zeroPadValue(accountAddress, 32),
        bytecode: accountProxyArtifact.bytecode
    })
    console.log("accountAddress", accountAddress)

    // account = new Contract(
    //     accountAddress,
    //     implementation.interface,
    //     fundingWallet,
    // );
    // // 0.0001 ETH transfered to Account
    // await (
    //     await fundingWallet.sendTransaction({
    //         to: await account.getAddress(),
    //         value: parseEther('0.0001'),
    //     })
    // ).wait();
}
