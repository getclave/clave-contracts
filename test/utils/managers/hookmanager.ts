/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ec } from 'elliptic';
import type { BytesLike } from 'ethers';
import type { Contract, Provider } from 'zksync-ethers';
import { utils } from 'zksync-ethers';

import type { HOOKS } from '../names';
import { prepareTeeTx } from '../transactions';

export async function addHook(
    provider: Provider,
    account: Contract,
    validator: Contract,
    hook: Contract,
    isValidation: HOOKS,
    keyPair: ec.KeyPair,
    hookData: Array<BytesLike> = [],
): Promise<void> {
    const addHookTx = await account.addHook.populateTransaction(
        await hook.getAddress(),
        isValidation == 1 ? true : false,
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        addHookTx,
        await validator.getAddress(),
        keyPair,
        hookData,
    );
    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function removeHook(
    provider: Provider,
    account: Contract,
    validator: Contract,
    hook: Contract,
    isValidation: HOOKS,
    keyPair: ec.KeyPair,
    hookData: Array<BytesLike> = [],
): Promise<void> {
    const removeHookTx = await account.removeHook.populateTransaction(
        await hook.getAddress(),
        isValidation == 1 ? true : false,
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        removeHookTx,
        await validator.getAddress(),
        keyPair,
        hookData,
    );
    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}
