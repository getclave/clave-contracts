/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ec } from 'elliptic';
import { concat } from 'ethers';
import type { Contract, Provider } from 'zksync-ethers';
import { utils } from 'zksync-ethers';

import { prepareTeeTx } from '../transactions';

export async function addModule(
    provider: Provider,
    account: Contract,
    validator: Contract,
    module: Contract,
    initData: string,
    keyPair: ec.KeyPair,
): Promise<void> {
    const moduleAndData = concat([await module.getAddress(), initData]);

    const addModuleTx = await account.addModule.populateTransaction(
        moduleAndData,
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        addModuleTx,
        await validator.getAddress(),
        keyPair,
    );
    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function removeModule(
    provider: Provider,
    account: Contract,
    validator: Contract,
    module: Contract,
    keyPair: ec.KeyPair,
): Promise<void> {
    const removeModuleTx = await account.removeModule.populateTransaction(
        await module.getAddress(),
    );

    const tx = await prepareTeeTx(
        provider,
        account,
        removeModuleTx,
        await validator.getAddress(),
        keyPair,
    );

    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}
