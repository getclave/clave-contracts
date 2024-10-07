/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import { ClaveAccount } from '../generated/schema';
import {
    Supply as SupplyEvent,
    Withdraw as WithdrawEvent,
} from '../generated/zeroUsdtPool/zeroUsdtPool';
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

const protocol = 'ZeroLend';

export function handleSupply(event: SupplyEvent): void {
    const account = ClaveAccount.load(event.params.onBehalfOf);
    if (!account) {
        return;
    }

    const pool = event.address;
    const token = event.params.reserve;
    const amount = event.params.amount;

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

    dailyEarnFlow.amountIn = dailyEarnFlow.amountIn.plus(amount);
    weeklyEarnFlow.amountIn = weeklyEarnFlow.amountIn.plus(amount);
    monthlyEarnFlow.amountIn = monthlyEarnFlow.amountIn.plus(amount);
    earnPosition.invested = earnPosition.invested.plus(amount);

    dailyEarnFlow.save();
    weeklyEarnFlow.save();
    monthlyEarnFlow.save();
    earnPosition.save();
}

export function handleWithdraw(event: WithdrawEvent): void {
    const account = ClaveAccount.load(event.params.to);
    if (!account) {
        return;
    }

    const pool = event.address;
    const token = event.params.reserve;
    const amount = event.params.amount;

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

    if (amount.gt(invested)) {
        const compoundGain = amount.minus(invested);
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
        dailyEarnFlow.amountOut = dailyEarnFlow.amountOut.plus(amount);
        weeklyEarnFlow.amountOut = weeklyEarnFlow.amountOut.plus(amount);
        monthlyEarnFlow.amountOut = monthlyEarnFlow.amountOut.plus(amount);
        earnPosition.invested = invested.minus(amount);
    }

    dailyEarnFlow.save();
    weeklyEarnFlow.save();
    monthlyEarnFlow.save();
    earnPosition.save();
}
