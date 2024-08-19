/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ec } from 'elliptic';
import {
    ZeroAddress,
    parseEther,
} from 'ethers';
import * as hre from 'hardhat';
import { Contract, Provider, Wallet, utils } from 'zksync-ethers';
import { LOCAL_RICH_WALLETS, deployContract, getWallet } from '../deploy/utils';
import type { CallStruct } from '../typechain-types/contracts/batch/BatchCaller';
import { genKeyK1, encodePublicKeyK1 } from '../test/utils/p256';
let provider: Provider;
let richWallet: Wallet;
let keyPair: ec.KeyPair;

let batchCaller: Contract;
let mockValidator: Contract;
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

    richWallet = getWallet(hre);

    keyPair = genKeyK1();
    const publicKey = encodePublicKeyK1(keyPair);

    batchCaller = await deployContract(hre, 'BatchCaller', undefined, {
        wallet: richWallet,
        silent: true,
    });

    mockValidator = await deployContract(hre, 'EOAValidator', undefined, {
        wallet: richWallet,
        silent: true,
    });

    implementation = await deployContract(
        hre,
        'ClaveImplementation',
        [await batchCaller.getAddress()],
        {
            wallet: richWallet,
            silent: true,
        },
    );

    registry = await deployContract(hre, 'ClaveRegistry', undefined, {
        wallet: richWallet,
        silent: true,
    });

    //TODO: WHY DOES THIS HELP
    await deployContract(
        hre,
        'ClaveProxy',
        [await implementation.getAddress()],
        { wallet: richWallet, silent: true },
    );

    const accountArtifact = await hre.zksyncEthers.loadArtifact('ClaveProxy');
    const bytecodeHash = utils.hashBytecode(accountArtifact.bytecode);
    factory = await deployContract(
        hre,
        'AccountFactory',
        [
            await implementation.getAddress(),
            await registry.getAddress(),
            bytecodeHash,
            richWallet.address,
        ],
        {
            wallet: richWallet,
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
                    await mockValidator.getAddress(),
                    [],
                    [call.target, call.allowFailure, call.value, call.callData],
                ],
            )
            .slice(2);

    const tx = await factory.deployAccount(salt, initializer);
    await tx.wait();

    const accountAddress = await factory.getAddressForSalt(salt);
    account = new Contract(
        accountAddress,
        implementation.interface,
        richWallet,
    );
    // 100 ETH transfered to Account
    await (
        await richWallet.sendTransaction({
            to: await account.getAddress(),
            value: parseEther('0.0069'),
        })
    ).wait();
}
