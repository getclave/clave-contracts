/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import { Swap as SwapEvent } from '../generated/OdosRouter/OdosRouter';
import {
    ClaveAccount,
    ERC20,
    InAppSwap,
    WeeklySwappedTo,
} from '../generated/schema';
import {
    ZERO,
    fetchTokenDecimals,
    fetchTokenName,
    fetchTokenSymbol,
    getOrCreateWeek,
} from './helpers';

export function handleSwap(event: SwapEvent): void {
    const account = ClaveAccount.load(event.params.sender);
    if (!account) {
        return;
    }

    const week = getOrCreateWeek(event.block.timestamp);

    const tokenOutAddress = event.params.outputToken;
    let tokenOut = ERC20.load(tokenOutAddress);
    if (!tokenOut) {
        tokenOut = new ERC20(tokenOutAddress);
        tokenOut.name = fetchTokenName(tokenOutAddress);
        tokenOut.symbol = fetchTokenSymbol(tokenOutAddress);
        tokenOut.decimals = fetchTokenDecimals(tokenOutAddress) as i32;
        tokenOut.totalAmount = ZERO;
        tokenOut.save();
    }

    const weeklySwappedToId = week.id.concat(tokenOut.id);
    let weeklySwappedTo = WeeklySwappedTo.load(weeklySwappedToId);
    if (!weeklySwappedTo) {
        weeklySwappedTo = new WeeklySwappedTo(weeklySwappedToId);
        weeklySwappedTo.week = week.id;
        weeklySwappedTo.erc20 = tokenOut.id;
        weeklySwappedTo.amount = ZERO;
    }

    weeklySwappedTo.amount = weeklySwappedTo.amount.plus(
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

    weeklySwappedTo.save();
    inAppSwap.save();
}
