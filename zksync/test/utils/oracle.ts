/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { Contract } from '@ethersproject/contracts';
import { DataServiceWrapper } from '@redstone-finance/evm-connector/dist/src/wrappers/DataServiceWrapper';

export const getOraclePayload = async (
    paymasterContract: Contract,
): Promise<string> => {
    const wrapper = new DataServiceWrapper({
        dataServiceId: 'redstone-primary-prod',
        dataFeeds: ['ETH'],
    });
    const redstonePayload = await wrapper.getRedstonePayloadForManualUsage(
        paymasterContract,
    );
    return redstonePayload;
};
