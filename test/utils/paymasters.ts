/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ethers } from 'ethers';
import { utils } from 'zksync-ethers';
import type { Contract, types } from 'zksync-ethers';

export function getGaslessPaymasterInput(
    paymasterAddress: types.Address,
): types.PaymasterParams {
    return utils.getPaymasterParams(paymasterAddress, {
        type: 'General',
        innerInput: new Uint8Array(),
    });
}

export function getERC20PaymasterInput(
    paymasterAddress: types.Address,
    tokenAddress: types.Address,
    minimalAllowance: bigint,
    oraclePayload: ethers.BytesLike,
): types.PaymasterParams {
    return utils.getPaymasterParams(paymasterAddress, {
        type: 'ApprovalBased',
        token: tokenAddress,
        minimalAllowance,
        innerInput: oraclePayload,
    });
}

export async function getOraclePayload(
    paymasterContract: Contract,
): Promise<string> {
    paymasterContract;
    return '0x';
}
