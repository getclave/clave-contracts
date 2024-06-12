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
    getOrCreateDay,
    getOrCreateMonth,
    getOrCreateWeek,
    getTotal,
} from './helpers';

export function handleSupply(event: SupplyEvent): void {
    const account = ClaveAccount.load(event.params.onBehalfOf);
    if (!account) {
        return;
    }

    const amount = event.params.amount;

    const day = getOrCreateDay(event.block.timestamp);
    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();

    day.investIn = day.investIn.plus(amount);
    week.investIn = week.investIn.plus(amount);
    month.investIn = month.investIn.plus(amount);
    total.invested = total.invested.plus(amount);
    account.invested = account.invested.plus(amount);

    day.save();
    week.save();
    month.save();
    total.save();
    account.save();
}

export function handleWithdraw(event: WithdrawEvent): void {
    const account = ClaveAccount.load(event.params.to);
    if (!account) {
        return;
    }

    const amount = event.params.amount;

    const day = getOrCreateDay(event.block.timestamp);
    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();

    day.investOut = day.investOut.plus(amount);
    week.investOut = week.investOut.plus(amount);
    month.investOut = month.investOut.plus(amount);
    total.invested = total.invested.minus(amount);
    account.invested = account.invested.minus(amount);

    day.save();
    week.save();
    month.save();
    total.save();
    account.save();
}
