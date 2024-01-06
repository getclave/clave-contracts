/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ec } from 'elliptic';
import { type BigNumberish, ethers } from 'ethers';
import { parseEther } from 'ethers/lib/utils';
import type { Provider, types } from 'zksync-web3';
import { EIP712Signer, utils } from 'zksync-web3';
import type { TransactionRequest } from 'zksync-web3/build/src/types';

import type { ClaveProxy } from '../../typechain-types';
import type { BatchCaller } from '../../typechain-types';
import { sign } from './p256';

export const ethTransfer = (
    to: string,
    value: BigNumberish,
): TransactionRequest => {
    return {
        to,
        value,
        data: '0x',
    };
};

export async function prepareMockTx(
    provider: Provider,
    account: ClaveProxy,
    tx: TransactionRequest,
    validatorAddress: string,
    paymasterParams?: types.PaymasterParams,
): Promise<TransactionRequest> {
    const abiCoder = ethers.utils.defaultAbiCoder;
    const signature = abiCoder.encode(
        ['bytes', 'address', 'bytes[]'],
        ['0x' + 'C1AE'.repeat(32), validatorAddress, []],
    );

    tx = {
        ...tx,
        from: account.address,
        nonce: await provider.getTransactionCount(account.address),
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
    account: ClaveProxy,
    tx: TransactionRequest,
    validatorAddress: string,
    keyPair: ec.KeyPair,
    hookData: Array<ethers.utils.BytesLike> = [],
    paymasterParams?: types.PaymasterParams,
): Promise<TransactionRequest> {
    if (tx.value == undefined) {
        tx.value = parseEther('0');
    }

    tx = {
        ...tx,
        from: account.address,
        nonce: await provider.getTransactionCount(account.address),
        gasLimit: 30_000_000,
        gasPrice: await provider.getGasPrice(),
        chainId: (await provider.getNetwork()).chainId,
        type: 113,
        customData: {
            gasPerPubdata: utils.DEFAULT_GAS_PER_PUBDATA_LIMIT,
            paymasterParams: paymasterParams,
        } as types.Eip712Meta,
    };

    const signedTxHash = EIP712Signer.getSignedDigest(tx);

    const abiCoder = ethers.utils.defaultAbiCoder;
    let signature = sign(signedTxHash.toString(), keyPair);

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
    account: ClaveProxy,
    BatchCallerAddress: string,
    calls: Array<BatchCaller.CallStruct>,
    validatorAddress: string,
    keyPair: ec.KeyPair,
    hookData: Array<ethers.utils.BytesLike> = [],
    paymasterParams?: types.PaymasterParams,
): Promise<TransactionRequest> {
    const abiCoder = ethers.utils.defaultAbiCoder;
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

    const tx = {
        to: BatchCallerAddress,
        from: account.address,
        nonce: await provider.getTransactionCount(account.address),
        gasLimit: 30_000_000,
        gasPrice: await provider.getGasPrice(),
        data,
        value: parseEther('0'),
        chainId: (await provider.getNetwork()).chainId,
        type: 113,
        customData: {
            gasPerPubdata: utils.DEFAULT_GAS_PER_PUBDATA_LIMIT,
            paymasterParams,
        } as types.Eip712Meta,
    };

    const signedTxHash = EIP712Signer.getSignedDigest(tx);

    let signature = sign(signedTxHash.toString(), keyPair);

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
