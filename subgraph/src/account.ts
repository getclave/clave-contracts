/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import { BigInt } from '@graphprotocol/graph-ts';

import { ClaveAccount, ClaveTransaction } from '../generated/schema';
import {
    FeePaid as FeePaidEvent,
    Upgraded as UpgradedEvent,
} from '../generated/templates/Account/ClaveImplementation';
import {
    getOrCreateDay,
    getOrCreateDayAccount,
    getOrCreateMonth,
    getOrCreateMonthAccount,
    getOrCreateWeek,
    getOrCreateWeekAccount,
    getTotal,
} from './helpers';

export function handleFeePaid(event: FeePaidEvent): void {
    const transaction = new ClaveTransaction(event.transaction.hash);
    const day = getOrCreateDay(event.block.timestamp);
    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();
    const account = ClaveAccount.load(event.address);
    if (account != null) {
        const dayAccount = getOrCreateDayAccount(account, day);
        dayAccount.save();
        const weekAccount = getOrCreateWeekAccount(account, week);
        weekAccount.save();
        const monthAccount = getOrCreateMonthAccount(account, month);
        monthAccount.save();

        account.txCount = account.txCount + 1;
        account.save();
    }
    day.transactions = day.transactions + 1;
    week.transactions = week.transactions + 1;
    month.transactions = month.transactions + 1;
    total.transactions = total.transactions + 1;
    transaction.sender = event.address;
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    transaction.to = event.transaction.to!;
    transaction.value = event.transaction.value;
    let gasUsed = BigInt.fromI32(0);
    const receipt = event.receipt;
    if (receipt != null) {
        gasUsed = receipt.gasUsed;
    }
    transaction.gasCost = event.transaction.gasPrice.times(gasUsed);
    transaction.paymaster = 'None';
    transaction.date = event.block.timestamp;

    day.save();
    week.save();
    month.save();
    total.save();
    transaction.save();
}

export function handleUpgraded(event: UpgradedEvent): void {
    const account = ClaveAccount.load(event.address);
    if (account == null) {
        return;
    }
    account.implementation = event.params.newImplementation;
    account.save();
}
