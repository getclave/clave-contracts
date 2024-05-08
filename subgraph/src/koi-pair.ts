/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import {
    Burn as BurnEvent,
    Claim as ClaimEvent,
    Mint as MintEvent,
} from '../generated/KoiUsdceUsdt/KoiPair';
import { ClaveAccount } from '../generated/schema';
import { getOrCreateMonth, getOrCreateWeek, getTotal } from './helpers';

export function handleMint(event: MintEvent): void {
    const account = ClaveAccount.load(event.params.sender);
    if (!account) {
        return;
    }

    const amount = event.params.amount1.plus(event.params.amount0);

    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();

    week.investIn = week.investIn.plus(amount);
    month.investIn = month.investIn.plus(amount);
    total.invested = total.invested.plus(amount);
    account.invested = account.invested.plus(amount);

    week.save();
    month.save();
    total.save();
    account.save();
}

export function handleBurn(event: BurnEvent): void {
    const account = ClaveAccount.load(event.params.sender);
    if (!account) {
        return;
    }

    const amount = event.params.amount1.plus(event.params.amount0);

    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();

    week.investOut = week.investOut.plus(amount);
    month.investOut = month.investOut.plus(amount);
    total.invested = total.invested.minus(amount);
    account.invested = account.invested.minus(amount);

    week.save();
    month.save();
    total.save();
    account.save();
}

export function handleClaim(event: ClaimEvent): void {
    const account = ClaveAccount.load(event.params.sender);
    if (!account) {
        return;
    }

    const amount = event.params.amount1.plus(event.params.amount0);

    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();

    week.realizedGain = week.realizedGain.plus(amount);
    month.realizedGain = month.realizedGain.plus(amount);
    total.realizedGain = total.realizedGain.plus(amount);
    account.realizedGain = account.realizedGain.plus(amount);

    week.save();
    month.save();
    total.save();
    account.save();
}
