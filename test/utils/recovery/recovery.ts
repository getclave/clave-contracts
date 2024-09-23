/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { AbiCoder, TypedDataEncoder } from 'ethers';
import { type Contract, type Wallet } from 'zksync-ethers';

type RecoveryEIP712DomainType = {
    name: string;
    version: string;
    chainId: number;
    verifyingContract: string;
};

type StartRecoveryParams = {
    recoveringAddress: string;
    newOwner: string;
    nonce: number;
};

async function signRecoveryEIP712Hash(
    params: StartRecoveryParams,
    recoveryContract: Contract,
    validator: Contract,
    wallet: Wallet,
): Promise<string> {
    const eip712Hash = await recoveryContract.getEip712Hash(params);

    const { chainId } = await wallet.provider.getNetwork();
    const numberChainId = Number(chainId);

    const eip1271Hash = TypedDataEncoder.hash(
        recoveryEIP712Domain(
            'TEST',
            '0',
            numberChainId,
            await recoveryContract.getAddress(),
        ),
        { ClaveMessage: [{ name: 'signedHash', type: 'bytes32' }] },
        {
            signedHash: eip712Hash,
        },
    );

    const signature = wallet.signingKey.sign(eip1271Hash).serialized;

    const abiCoder = AbiCoder.defaultAbiCoder();
    const encodedSignature = abiCoder.encode(
        ['bytes', 'address'],
        [signature, await validator.getAddress()],
    );

    return encodedSignature;
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
        params,
        module,
        validator,
        cloudGuardian,
    );

    const startRecoveryTx = await module.startRecovery(params, signature);
    await startRecoveryTx.wait();
}

const recoveryEIP712Domain = (
    name: string,
    version: string,
    chainId: number,
    verifyingContract: string,
): RecoveryEIP712DomainType => {
    return {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: verifyingContract,
    };
};
