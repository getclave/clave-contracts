/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import { Swap as SwapEvent } from '../generated/OdosRouter/OdosRouter';
import {
    ClaveAccount,
    DailySwappedTo,
    InAppSwap,
    MonthlySwappedTo,
    WeeklySwappedTo,
} from '../generated/schema';
import {
    ZERO,
    getOrCreateDay,
    getOrCreateMonth,
    getOrCreateWeek,
} from './helpers';

export function handleSwap(event: SwapEvent): void {
    const account = ClaveAccount.load(event.params.sender);
    if (!account) {
        return;
    }

    const day = getOrCreateDay(event.block.timestamp);
    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);

    const tokenOutAddress = event.params.outputToken;
    const dailySwappedToId = day.id.concat(tokenOutAddress);
    let dailySwappedTo = DailySwappedTo.load(dailySwappedToId);
    if (!dailySwappedTo) {
        dailySwappedTo = new DailySwappedTo(dailySwappedToId);
        dailySwappedTo.day = day.id;
        dailySwappedTo.erc20 = tokenOutAddress;
        dailySwappedTo.amount = ZERO;
    }

    dailySwappedTo.amount = dailySwappedTo.amount.plus(event.params.amountOut);

    const weeklySwappedToId = week.id.concat(tokenOutAddress);
    let weeklySwappedTo = WeeklySwappedTo.load(weeklySwappedToId);
    if (!weeklySwappedTo) {
        weeklySwappedTo = new WeeklySwappedTo(weeklySwappedToId);
        weeklySwappedTo.week = week.id;
        weeklySwappedTo.erc20 = tokenOutAddress;
        weeklySwappedTo.amount = ZERO;
    }

    weeklySwappedTo.amount = weeklySwappedTo.amount.plus(
        event.params.amountOut,
    );

    const monthlySwappedToId = month.id.concat(tokenOutAddress);
    let monthlySwappedTo = MonthlySwappedTo.load(monthlySwappedToId);
    if (!monthlySwappedTo) {
        monthlySwappedTo = new MonthlySwappedTo(monthlySwappedToId);
        monthlySwappedTo.month = month.id;
        monthlySwappedTo.erc20 = tokenOutAddress;
        monthlySwappedTo.amount = ZERO;
    }

    monthlySwappedTo.amount = monthlySwappedTo.amount.plus(
        event.params.amountOut,
    );

    const inAppSwap = new InAppSwap(
        event.transaction.hash.concatI32(event.logIndex.toI32()),
    );

    inAppSwap.account = account.id;
    inAppSwap.amountIn = event.params.inputAmount;
    inAppSwap.tokenIn = event.params.inputToken;
    inAppSwap.amountOut = event.params.amountOut;
    inAppSwap.tokenOut = event.params.outputToken;
    inAppSwap.date = event.block.timestamp;

    dailySwappedTo.save();
    weeklySwappedTo.save();
    monthlySwappedTo.save();
    inAppSwap.save();
}
