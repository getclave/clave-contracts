/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import { log } from '@graphprotocol/graph-ts';

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

const tokens = [
    '0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4',
    '0x493257fD37EDB34451f62EDf8D2a0C418852bA4C',
    '0x4B9eb6c0b6ea15176BBF62841C6B2A8a398cb656',
    '0x1d17cbcf0d6d143135ae902365d2e5e2a16538d4',
];

export function handleSupply(event: SupplyEvent): void {
    const account = ClaveAccount.load(event.params.onBehalfOf);
    if (!account) {
        return;
    }

    // skip if event.params.reserve not in tokens
    if (tokens.indexOf(event.params.reserve.toHexString()) === -1) {
        log.info('Skipped: {}', [event.params.reserve.toHexString()]);
        return;
    }

    log.info('Supply: {}', [event.params.reserve.toHexString()]);

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
