/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ec } from 'elliptic';
import type { Contract, Provider } from 'zksync-ethers';
import { utils } from 'zksync-ethers';

import { prepareTeeTx } from '../transactions';

export async function addR1Validator(
    provider: Provider,
    account: Contract,
    validator: Contract,
    newR1Validator: Contract,
    keyPair: ec.KeyPair,
): Promise<void> {
    const addValidatorTx = await account.r1AddValidator.populateTransaction(
        await newR1Validator.getAddress(),
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        addValidatorTx,
        await validator.getAddress(),
        keyPair,
    );
    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function removeR1Validator(
    provider: Provider,
    account: Contract,
    validator: Contract,
    removingR1Validator: Contract,
    keyPair: ec.KeyPair,
): Promise<void> {
    const removeValidatorTx =
        await account.r1RemoveValidator.populateTransaction(
            removingR1Validator,
        );
    const tx = await prepareTeeTx(
        provider,
        account,
        removeValidatorTx,
        await validator.getAddress(),
        keyPair,
    );
    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function addK1Validator(
    provider: Provider,
    account: Contract,
    validator: Contract,
    newK1Validator: Contract,
    keyPair: ec.KeyPair,
): Promise<void> {
    const addValidatorTx = await account.k1AddValidator.populateTransaction(
        await newK1Validator.getAddress(),
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        addValidatorTx,
        await validator.getAddress(),
        keyPair,
    );
    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function removeK1Validator(
    provider: Provider,
    account: Contract,
    validator: Contract,
    removingK1Validator: Contract,
    keyPair: ec.KeyPair,
): Promise<void> {
    const removeValidatorTx =
        await account.k1RemoveValidator.populateTransaction(
            removingK1Validator,
        );
    const tx = await prepareTeeTx(
        provider,
        account,
        removeValidatorTx,
        await validator.getAddress(),
        keyPair,
    );
    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}
