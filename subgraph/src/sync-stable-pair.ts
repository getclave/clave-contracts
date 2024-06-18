/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import { Address } from '@graphprotocol/graph-ts';

import {
    Burn as BurnEvent,
    Mint as MintEvent,
} from '../generated/SyncEthWstethPool/SyncStablePool';
import { ClaveAccount } from '../generated/schema';
import {
    ZERO,
    getOrCreateDailyEarnFlow,
    getOrCreateDay,
    getOrCreateEarnPosition,
    getOrCreateMonth,
    getOrCreateMonthlyEarnFlow,
    getOrCreateWeek,
    getOrCreateWeeklyEarnFlow,
} from './helpers';

const protocol = 'SyncSwap';
const token = Address.fromHexString(
    '0x000000000000000000000000000000000000800A',
);

export function handleMint(event: MintEvent): void {
    const account = ClaveAccount.load(event.transaction.from);
    if (!account) {
        return;
    }

    const pool = event.address;
    const amount0 = event.params.amount0;
    const amount1 = event.params.amount1;

    if (amount1.gt(ZERO)) {
        return;
    }

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

    dailyEarnFlow.amountIn = dailyEarnFlow.amountIn.plus(amount0);
    weeklyEarnFlow.amountIn = weeklyEarnFlow.amountIn.plus(amount0);
    monthlyEarnFlow.amountIn = monthlyEarnFlow.amountIn.plus(amount0);
    earnPosition.invested = earnPosition.invested.plus(amount0);

    dailyEarnFlow.save();
    weeklyEarnFlow.save();
    monthlyEarnFlow.save();
    earnPosition.save();
}

export function handleBurn(event: BurnEvent): void {
    const account = ClaveAccount.load(event.transaction.from);
    if (!account) {
        return;
    }

    const pool = event.address;
    const amount0 = event.params.amount0;
    const amount1 = event.params.amount1;

    if (amount1.gt(ZERO)) {
        return;
    }

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

    const invested = earnPosition.invested;

    if (amount0.gt(invested)) {
        const compoundGain = amount0.minus(invested);
        dailyEarnFlow.amountOut = dailyEarnFlow.amountOut.plus(invested);
        dailyEarnFlow.claimedGain =
            dailyEarnFlow.claimedGain.plus(compoundGain);
        weeklyEarnFlow.amountOut = weeklyEarnFlow.amountOut.plus(invested);
        weeklyEarnFlow.claimedGain =
            weeklyEarnFlow.claimedGain.plus(compoundGain);
        monthlyEarnFlow.amountOut = monthlyEarnFlow.amountOut.plus(invested);
        monthlyEarnFlow.claimedGain =
            monthlyEarnFlow.claimedGain.plus(compoundGain);
        earnPosition.invested = ZERO;
        earnPosition.compoundGain =
            earnPosition.compoundGain.plus(compoundGain);
    } else {
        dailyEarnFlow.amountOut = dailyEarnFlow.amountOut.plus(amount0);
        weeklyEarnFlow.amountOut = weeklyEarnFlow.amountOut.plus(amount0);
        monthlyEarnFlow.amountOut = monthlyEarnFlow.amountOut.plus(amount0);
        earnPosition.invested = earnPosition.invested.minus(amount0);
    }

    dailyEarnFlow.save();
    weeklyEarnFlow.save();
    monthlyEarnFlow.save();
    earnPosition.save();
}
