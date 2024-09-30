/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { type Contract, type Wallet } from 'zksync-ethers';

type StartRecoveryParams = {
    recoveringAddress: string;
    newOwner: string;
    nonce: number;
};

async function signRecoveryEIP712Hash(
    account: Contract,
    params: StartRecoveryParams,
    recoveryContract: Contract,
    validator: Contract,
    wallet: Wallet,
): Promise<string> {
    const eip712Hash = await recoveryContract.getEip712Hash(params);
    const signature = wallet.signingKey.sign(eip712Hash).serialized;
    return signature;
}

export async function startRecovery(
    cloudGuardian: Wallet,
    account: Contract,
    module: Contract,
    validator: Contract,
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
        account,
        params,
        module,
        validator,
        cloudGuardian,
    );

    const startRecoveryTx = await module.startRecovery(params, signature);
    await startRecoveryTx.wait();
}
