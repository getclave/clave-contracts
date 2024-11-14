/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import { Address } from '@graphprotocol/graph-ts';

import { DistributedSupplierRewardToken as DistributedSupplierRewardTokenEvent } from '../generated/VenusReward/VenusReward';
import { ClaveAccount } from '../generated/schema';
import {
    getOrCreateDailyEarnFlow,
    getOrCreateDay,
    getOrCreateEarnPosition,
    getOrCreateMonth,
    getOrCreateMonthlyEarnFlow,
    getOrCreateWeek,
    getOrCreateWeeklyEarnFlow,
} from './helpers';

const protocol = 'Venus';
const token = Address.fromHexString(
    '0xD78ABD81a3D57712a3af080dc4185b698Fe9ac5A',
);

export function handleDistributedSupplierRewardToken(
    event: DistributedSupplierRewardTokenEvent,
): void {
    const account = ClaveAccount.load(event.params.supplier);
    if (!account) {
        return;
    }

    const pool = event.address;
    const amount = event.params.rewardTokenTotal;

    const day = getOrCreateDay(event.block.timestamp);
    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);

    const dailyEarnFlow = getOrCreateDailyEarnFlow(day, token, protocol);
    const weeklyEarnFlow = getOrCreateWeeklyEarnFlow(week, token, protocol);
    const monthlyEarnFlow = getOrCreateMonthlyEarnFlow(month, token, protocol);
    const earnPosition = getOrCreateEarnPosition(
        account,
        pool,
        token,
        protocol,
    );

    dailyEarnFlow.claimedGain = dailyEarnFlow.claimedGain.plus(amount);
    weeklyEarnFlow.claimedGain = weeklyEarnFlow.claimedGain.plus(amount);
    monthlyEarnFlow.claimedGain = monthlyEarnFlow.claimedGain.plus(amount);
    earnPosition.normalGain = earnPosition.normalGain.plus(amount);

    dailyEarnFlow.save();
    weeklyEarnFlow.save();
    monthlyEarnFlow.save();
    earnPosition.save();
}
