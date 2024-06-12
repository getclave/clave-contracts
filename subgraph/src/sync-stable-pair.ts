/* eslint-disable @typescript-eslint/consistent-type-imports */
import {
    Burn as BurnEvent,
    Mint as MintEvent,
} from '../generated/SyncEthWstethPool/SyncStablePool';
import { ClaveAccount } from '../generated/schema';
import {
    getOrCreateDay,
    getOrCreateMonth,
    getOrCreateWeek,
    getTotal,
} from './helpers';

export function handleMint(event: MintEvent): void {
    const account = ClaveAccount.load(event.transaction.from);
    if (!account) {
        return;
    }

    const amount = event.params.amount1.plus(event.params.amount0);

    const day = getOrCreateDay(event.block.timestamp);
    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();

    day.investInEth = day.investInEth.plus(amount);
    week.investInEth = week.investInEth.plus(amount);
    month.investInEth = month.investInEth.plus(amount);
    total.investedEth = total.investedEth.plus(amount);
    account.investedEth = account.investedEth.plus(amount);

    day.save();
    week.save();
    month.save();
    total.save();
    account.save();
}

export function handleBurn(event: BurnEvent): void {
    const account = ClaveAccount.load(event.transaction.from);
    if (!account) {
        return;
    }

    const amount = event.params.amount1.plus(event.params.amount0);

    const day = getOrCreateDay(event.block.timestamp);
    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();

    day.investOutEth = day.investOutEth.plus(amount);
    week.investOutEth = week.investOutEth.plus(amount);
    month.investOutEth = month.investOutEth.plus(amount);
    total.investedEth = total.investedEth.minus(amount);
    account.investedEth = account.investedEth.minus(amount);

    day.save();
    week.save();
    month.save();
    total.save();
    account.save();
}
