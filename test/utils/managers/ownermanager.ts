/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ec } from 'elliptic';
import type { Contract, Provider } from 'zksync-ethers';
import { utils } from 'zksync-ethers';

import { prepareTeeTx } from '../transactions';

export async function addR1Key(
    provider: Provider,
    account: Contract,
    validator: Contract,
    newPublicKey: string,
    keyPair: ec.KeyPair,
): Promise<void> {
    const addOwnerTx = await account.r1AddOwner.populateTransaction(
        newPublicKey,
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        addOwnerTx,
        await validator.getAddress(),
        keyPair,
    );

    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function addK1Key(
    provider: Provider,
    account: Contract,
    validator: Contract,
    newK1Address: string,
    keyPair: ec.KeyPair,
): Promise<void> {
    const addOwnerTx = await account.k1AddOwner.populateTransaction(
        newK1Address,
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        addOwnerTx,
        await validator.getAddress(),
        keyPair,
    );
    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function removeR1Key(
    provider: Provider,
    account: Contract,
    validator: Contract,
    removingPublicKey: string,
    keyPair: ec.KeyPair,
): Promise<void> {
    const removeOwnerTxData = await account.r1RemoveOwner.populateTransaction(
        removingPublicKey,
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        removeOwnerTxData,
        await validator.getAddress(),
        keyPair,
    );

    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function removeK1Key(
    provider: Provider,
    account: Contract,
    validator: Contract,
    removingAddress: string,
    keyPair: ec.KeyPair,
): Promise<void> {
    const removeOwnerTx = await account.k1RemoveOwner.populateTransaction(
        removingAddress,
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        removeOwnerTx,
        await validator.getAddress(),
        keyPair,
    );
    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function resetOwners(
    provider: Provider,
    account: Contract,
    validator: Contract,
    newPublicKey: string,
    keyPair: ec.KeyPair,
): Promise<void> {
    const resetOwnersTx = await account.resetOwners.populateTransaction(
        newPublicKey,
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        resetOwnersTx,
        await validator.getAddress(),
        keyPair,
    );

    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}
