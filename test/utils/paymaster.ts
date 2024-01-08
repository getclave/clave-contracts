/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { ethers } from 'ethers';
import { type types, utils } from 'zksync-ethers';

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
