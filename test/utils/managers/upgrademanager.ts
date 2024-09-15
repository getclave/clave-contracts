/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ec } from 'elliptic';
import type { Contract, Provider } from 'zksync-ethers';
import { utils } from 'zksync-ethers';

import { prepareTeeTx } from '../transactions';

export async function upgradeTx(
    provider: Provider,
    account: Contract,
    validator: Contract,
    newImplementation: Contract,
    keyPair: ec.KeyPair,
): Promise<void> {
    const upgradeTx = await account.upgradeTo.populateTransaction(
        await newImplementation.getAddress(),
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        upgradeTx,
        await validator.getAddress(),
        keyPair,
    );
    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}
