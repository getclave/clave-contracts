/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ec } from 'elliptic';
import { type BigNumberish, ethers, parseEther } from 'ethers';
import type { Contract, Provider, types } from 'zksync-ethers';
import { EIP712Signer, utils } from 'zksync-ethers';

import type { ClaveProxy } from '../../typechain-types';
import type { CallStruct } from '../../typechain-types/contracts/batch/BatchCaller';
import { sign } from './p256';

export const ethTransfer = (
    to: string,
    value: BigNumberish,
): types.TransactionLike => {
    return {
        to,
        value,
        data: '0x',
    };
};

export async function prepareMockTx(
    provider: Provider,
    account: ClaveProxy,
    tx: types.TransactionLike,
    validatorAddress: string,
    paymasterParams?: types.PaymasterParams,
): Promise<types.TransactionLike> {
    const abiCoder = ethers.AbiCoder.defaultAbiCoder();
    const signature = abiCoder.encode(
        ['bytes', 'address', 'bytes[]'],
        ['0x' + 'C1AE'.repeat(32), validatorAddress, []],
    );

    tx = {
        ...tx,
        from: await account.getAddress(),
        nonce: await provider.getTransactionCount(await account.getAddress()),
        gasLimit: 10_000_000,
        gasPrice: await provider.getGasPrice(),
        chainId: (await provider.getNetwork()).chainId,
        type: 113,
        customData: {
            gasPerPubdata: utils.DEFAULT_GAS_PER_PUBDATA_LIMIT,
            customSignature: signature,
            paymasterParams: paymasterParams,
        } as types.Eip712Meta,
    };

    return tx;
}

export async function prepareTeeTx(
    provider: Provider,
    account: Contract,
    tx: types.TransactionLike,
    validatorAddress: string,
    keyPair: ec.KeyPair,
    hookData: Array<ethers.BytesLike> = [],
    paymasterParams?: types.PaymasterParams,
): Promise<types.TransactionLike> {
    if (tx.value == undefined) {
        tx.value = parseEther('0');
    }

    const chainId = (await provider.getNetwork()).chainId;
    tx = {
        ...tx,
        from: await account.getAddress(),
        nonce: await provider.getTransactionCount(await account.getAddress()),
        gasLimit: 30_000_000,
        gasPrice: await provider.getGasPrice(),
        chainId: chainId,
        type: 113,
        customData: {
            gasPerPubdata: utils.DEFAULT_GAS_PER_PUBDATA_LIMIT,
            paymasterParams: paymasterParams,
        } as types.Eip712Meta,
    };

    const signedTxHash = EIP712Signer.getSignedDigest(tx);

    let signature = await sign(signedTxHash.toString(), keyPair, chainId, validatorAddress);

    const abiCoder = ethers.AbiCoder.defaultAbiCoder();
    signature = abiCoder.encode(
        ['bytes', 'address', 'bytes[]'],
        [signature, validatorAddress, hookData],
    );

    tx.customData = {
        ...tx.customData,
        customSignature: signature,
    };

    return tx;
}

export async function prepareBatchTx(
    provider: Provider,
    account: Contract,
    BatchCallerAddress: string,
    calls: Array<CallStruct>,
    validatorAddress: string,
    keyPair: ec.KeyPair,
    hookData: Array<ethers.BytesLike> = [],
    paymasterParams?: types.PaymasterParams,
): Promise<types.TransactionLike> {
    const abiCoder = ethers.AbiCoder.defaultAbiCoder();
    const data =
        '0x8f0273a9' +
        abiCoder
            .encode(
                [
                    'tuple(address target, bool allowFailure, uint256 value, bytes callData)[]',
                ],
                [calls],
            )
            .slice(2);

    const chainId = (await provider.getNetwork()).chainId;
    const tx = {
        to: BatchCallerAddress,
        from: await account.getAddress(),
        nonce: await provider.getTransactionCount(await account.getAddress()),
        gasLimit: 30_000_000,
        gasPrice: await provider.getGasPrice(),
        data,
        value: parseEther('0'),
        chainId: chainId,
        type: 113,
        customData: {
            gasPerPubdata: utils.DEFAULT_GAS_PER_PUBDATA_LIMIT,
            paymasterParams,
        } as types.Eip712Meta,
    };

    const signedTxHash = EIP712Signer.getSignedDigest(tx);

    let signature = await sign(signedTxHash.toString(), keyPair, chainId, validatorAddress);

    signature = abiCoder.encode(
        ['bytes', 'address', 'bytes[]'],
        [signature, validatorAddress, hookData],
    );

    tx.customData = {
        ...tx.customData,
        customSignature: signature,
    };

    return tx;
}
