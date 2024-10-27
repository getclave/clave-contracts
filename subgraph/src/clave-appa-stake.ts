/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import {
    RewardPaid as RewardPaidEvent,
    Staked as StakedEvent,
    Withdrawn as WithdrawnEvent,
} from '../generated/ClaveAPPAStake/ZtakeV2';
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

const protocol = 'Clave';

export function handleStaked(event: StakedEvent): void {
    const account = ClaveAccount.load(event.params.user);
    if (!account) {
        return;
    }

    const pool = event.address;
    const token = event.params.token;
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

export function handleWithdrawn(event: WithdrawnEvent): void {
    const account = ClaveAccount.load(event.transaction.from);
    if (!account) {
        return;
    }

    const pool = event.address;
    const token = event.params.token;
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

    dailyEarnFlow.amountOut = dailyEarnFlow.amountOut.plus(amount);
    weeklyEarnFlow.amountOut = weeklyEarnFlow.amountOut.plus(amount);
    monthlyEarnFlow.amountOut = monthlyEarnFlow.amountOut.plus(amount);
    earnPosition.invested = earnPosition.invested.minus(amount);

    dailyEarnFlow.save();
    weeklyEarnFlow.save();
    monthlyEarnFlow.save();
    earnPosition.save();
}

export function handleRewardPaid(event: RewardPaidEvent): void {
    const account = ClaveAccount.load(event.params.user);
    if (!account) {
        return;
    }

    const pool = event.address;
    const token = event.params.token;
    const amount = event.params.reward;

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
