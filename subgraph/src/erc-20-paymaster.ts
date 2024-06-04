/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import { BigInt } from '@graphprotocol/graph-ts';

import { ERC20PaymasterUsed as ERC20PaymasterUsedEvent } from '../generated/ERC20Paymaster/ERC20Paymaster';
import { ClaveAccount, ClaveTransaction } from '../generated/schema';
import {
    getOrCreateMonth,
    getOrCreateMonthAccount,
    getOrCreateWeek,
    getOrCreateWeekAccount,
    getTotal,
} from './helpers';

export function handleERC20PaymasterUsed(event: ERC20PaymasterUsedEvent): void {
    const account = ClaveAccount.load(event.params.user);
    if (!account) {
        return;
    }

    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();
    week.transactions = week.transactions + 1;
    month.transactions = month.transactions + 1;
    total.transactions = total.transactions + 1;

    const weekAccount = getOrCreateWeekAccount(account, week);
    weekAccount.save();
    const monthAccount = getOrCreateMonthAccount(account, month);
    monthAccount.save();

    const transaction = new ClaveTransaction(event.transaction.hash);
    transaction.sender = event.transaction.from;
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    transaction.to = event.transaction.to!;
    transaction.value = event.transaction.value;
    let gasUsed = BigInt.fromI32(0);
    const receipt = event.receipt;
    if (receipt != null) {
        gasUsed = receipt.gasUsed;
    }
    transaction.gasCost = event.transaction.gasPrice.times(gasUsed);
    transaction.paymaster = 'ERC20';
    transaction.date = event.block.timestamp;

    account.txCount = account.txCount + 1;
    account.save();

    week.save();
    month.save();
    total.save();
    transaction.save();
}
