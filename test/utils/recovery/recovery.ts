/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ec } from 'elliptic';
import type { Contract, Provider, Wallet } from 'zksync-ethers';
import { utils } from 'zksync-ethers';

import { encodePublicKey } from '../p256';
import { prepareTeeTx } from '../transactions';

type StartRecoveryParams = {
    recoveringAddress: string;
    newOwner: string;
    nonce: number;
};

type RecoveryData = {
    recoveringAddress: string;
    newOwner: string;
    nonce: number;
};

async function signRecoveryEIP712Hash(
    params: StartRecoveryParams | RecoveryData,
    recoveryContract: Contract,
    wallet: Wallet,
): Promise<string> {
    const eip712Hash = await recoveryContract.getEip712Hash(params);
    const signature = wallet.signingKey.sign(eip712Hash).serialized;
    return signature;
}

export async function startCloudRecovery(
    cloudGuardian: Wallet,
    account: Contract,
    module: Contract,
    newOwner: string,
): Promise<void> {
    const recoveringAddress = await account.getAddress();
    const recoveryNonce = await module.recoveryNonces(recoveringAddress);

    const params: StartRecoveryParams = {
        recoveringAddress: recoveringAddress,
        newOwner,
        nonce: recoveryNonce,
    };

    const signature = await signRecoveryEIP712Hash(
        params,
        module,
        cloudGuardian,
    );

    const startRecoveryTx = await module.startRecovery(params, signature);
    await startRecoveryTx.wait();
}

export async function startSocialRecovery(
    socialGuardian: Wallet,
    account: Contract,
    module: Contract,
    newKeyPair: ec.KeyPair,
): Promise<void> {
    const recoveringAddress = await account.getAddress();
    const recoveryNonce = await module.recoveryNonces(recoveringAddress);

    const recoveryData = {
        recoveringAddress: await account.getAddress(),
        newOwner: encodePublicKey(newKeyPair),
        nonce: recoveryNonce,
    };

    const signature = await signRecoveryEIP712Hash(
        recoveryData,
        module,
        socialGuardian,
    );

    const guardianData = {
        guardian: await socialGuardian.getAddress(),
        signature: signature,
    };

    const startRecoveryTx = await module.startRecovery(recoveryData, [
        guardianData,
    ]);
    await startRecoveryTx.wait();
}

export async function stopRecovery(
    provider: Provider,
    account: Contract,
    module: Contract,
    validator: Contract,
    keyPair: ec.KeyPair,
): Promise<void> {
    const stopRecoveryTx = await module.stopRecovery.populateTransaction();

    const tx = await prepareTeeTx(
        provider,
        account,
        stopRecoveryTx,
        await validator.getAddress(),
        keyPair,
    );

    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function updateCloudGuardian(
    provider: Provider,
    account: Contract,
    module: Contract,
    validator: Contract,
    newAddress: string,
    keyPair: ec.KeyPair,
): Promise<void> {
    const updateGuardianTx = await module.updateGuardian.populateTransaction(
        newAddress,
    );
    const tx = await prepareTeeTx(
        provider,
        account,
        updateGuardianTx,
        await validator.getAddress(),
        keyPair,
    );

    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function updateSocialRecoveryConfig(
    provider: Provider,
    account: Contract,
    module: Contract,
    validator: Contract,
    config: [number, number, Array<string>],
    keyPair: ec.KeyPair,
): Promise<void> {
    const updateConfigTx = await module.updateConfig.populateTransaction({
        threshold: config[0],
        timelock: config[1],
        guardians: config[2],
    });

    const tx = await prepareTeeTx(
        provider,
        account,
        updateConfigTx,
        await validator.getAddress(),
        keyPair,
    );
    const txReceipt = await provider.broadcastTransaction(
        utils.serializeEip712(tx),
    );
    await txReceipt.wait();
}

export async function executeRecovery(
    account: Contract,
    module: Contract,
): Promise<void> {
    const tx = await module.executeRecovery(await account.getAddress());
    await tx.wait();
}
