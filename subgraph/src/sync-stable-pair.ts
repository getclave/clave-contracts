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
const tokenb = Address.fromHexString(
    '0x703b52F2b28fEbcB60E1372858AF5b18849FE867',
);

export function handleMint(event: MintEvent): void {
    const account = ClaveAccount.load(event.transaction.from);
    if (!account) {
        return;
    }

    const pool = event.address;
    const amount0 = event.params.amount0;
    const amount1 = event.params.amount1;

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

    const dailyEarnFlow2 = getOrCreateDailyEarnFlow(day, tokenb, protocol);
    const weeklyEarnFlow2 = getOrCreateWeeklyEarnFlow(week, tokenb, protocol);
    const monthlyEarnFlow2 = getOrCreateMonthlyEarnFlow(
        month,
        tokenb,
        protocol,
    );
    const earnPosition2 = getOrCreateEarnPosition(
        account,
        pool,
        tokenb,
        protocol,
    );

    dailyEarnFlow2.amountIn = dailyEarnFlow2.amountIn.plus(amount1);
    weeklyEarnFlow2.amountIn = weeklyEarnFlow2.amountIn.plus(amount1);
    monthlyEarnFlow2.amountIn = monthlyEarnFlow2.amountIn.plus(amount1);
    earnPosition2.invested = earnPosition2.invested.plus(amount1);

    dailyEarnFlow.save();
    weeklyEarnFlow.save();
    monthlyEarnFlow.save();
    earnPosition.save();

    dailyEarnFlow2.save();
    weeklyEarnFlow2.save();
    monthlyEarnFlow2.save();
    earnPosition2.save();
}

export function handleBurn(event: BurnEvent): void {
    const account = ClaveAccount.load(event.transaction.from);
    if (!account) {
        return;
    }

    const pool = event.address;
    const amount0 = event.params.amount0;
    const amount1 = event.params.amount1;

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

    const dailyEarnFlow2 = getOrCreateDailyEarnFlow(day, tokenb, protocol);
    const weeklyEarnFlow2 = getOrCreateWeeklyEarnFlow(week, tokenb, protocol);
    const monthlyEarnFlow2 = getOrCreateMonthlyEarnFlow(
        month,
        tokenb,
        protocol,
    );
    const earnPosition2 = getOrCreateEarnPosition(
        account,
        pool,
        tokenb,
        protocol,
    );

    const invested2 = earnPosition2.invested;

    if (amount1.gt(invested2)) {
        const compoundGain2 = amount1.minus(invested2);
        dailyEarnFlow2.amountOut = dailyEarnFlow2.amountOut.plus(invested2);
        dailyEarnFlow2.claimedGain =
            dailyEarnFlow2.claimedGain.plus(compoundGain2);
        weeklyEarnFlow2.amountOut = weeklyEarnFlow2.amountOut.plus(invested2);
        weeklyEarnFlow2.claimedGain =
            weeklyEarnFlow2.claimedGain.plus(compoundGain2);
        monthlyEarnFlow2.amountOut = monthlyEarnFlow2.amountOut.plus(invested2);
        monthlyEarnFlow2.claimedGain =
            monthlyEarnFlow2.claimedGain.plus(compoundGain2);
        earnPosition2.invested = ZERO;
        earnPosition2.compoundGain =
            earnPosition2.compoundGain.plus(compoundGain2);
    } else {
        dailyEarnFlow2.amountOut = dailyEarnFlow2.amountOut.plus(amount1);
        weeklyEarnFlow2.amountOut = weeklyEarnFlow2.amountOut.plus(amount1);
        monthlyEarnFlow2.amountOut = monthlyEarnFlow2.amountOut.plus(amount1);
        earnPosition2.invested = earnPosition2.invested.minus(amount1);
    }

    dailyEarnFlow.save();
    weeklyEarnFlow.save();
    monthlyEarnFlow.save();
    earnPosition.save();

    dailyEarnFlow2.save();
    weeklyEarnFlow2.save();
    monthlyEarnFlow2.save();
    earnPosition2.save();
}
