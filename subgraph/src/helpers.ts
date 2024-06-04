/* eslint-disable @typescript-eslint/ban-types */

/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */

/* eslint-disable prefer-const */
import { Bytes } from '@graphprotocol/graph-ts';
import { BigInt } from '@graphprotocol/graph-ts';

import {
    ClaveAccount,
    Month,
    MonthAccount,
    Total,
    Week,
    WeekAccount,
} from '../generated/schema';

export const ZERO = BigInt.fromI32(0);
export const ONE = BigInt.fromI32(1);
const START_TIMESTAMP = BigInt.fromU32(1706045075);
const WEEK = BigInt.fromU32(604_800);
const MONTH = BigInt.fromU32(2_592_000);

export function getOrCreateWeek(timestamp: BigInt): Week {
    let weekNumber = timestamp.minus(START_TIMESTAMP).div(WEEK);
    let weekId = Bytes.fromByteArray(
        Bytes.fromBigInt(START_TIMESTAMP.plus(weekNumber.times(WEEK))),
    );
    let week = Week.load(weekId);

    if (week !== null) {
        return week;
    }

    week = new Week(weekId);
    week.createdAccounts = 0;
    week.deployedAccounts = 0;
    week.activeAccounts = 0;
    week.transactions = 0;
    week.investIn = ZERO;
    week.investOut = ZERO;
    week.realizedGain = ZERO;
    week.gasSponsored = ZERO;

    return week;
}

export function getOrCreateWeekAccount(
    account: ClaveAccount,
    week: Week,
): WeekAccount {
    let weekAccountId = account.id.concat(week.id);
    let weekAccount = WeekAccount.load(weekAccountId);

    if (weekAccount != null) {
        return weekAccount;
    }

    week.activeAccounts = week.activeAccounts + 1;

    weekAccount = new WeekAccount(weekAccountId);
    weekAccount.account = account.id;
    weekAccount.week = week.id;

    return weekAccount;
}

export function getOrCreateMonth(timestamp: BigInt): Month {
    let monthNumber = timestamp.minus(START_TIMESTAMP).div(MONTH);
    let monthId = Bytes.fromByteArray(
        Bytes.fromBigInt(START_TIMESTAMP.plus(monthNumber.times(MONTH))),
    ).concat(Bytes.fromHexString('0x00'));
    let month = Month.load(monthId);

    if (month !== null) {
        return month;
    }

    month = new Month(monthId);
    month.createdAccounts = 0;
    month.deployedAccounts = 0;
    month.activeAccounts = 0;
    month.transactions = 0;
    month.investIn = ZERO;
    month.investOut = ZERO;
    month.realizedGain = ZERO;
    month.gasSponsored = ZERO;

    return month;
}

export function getOrCreateMonthAccount(
    account: ClaveAccount,
    month: Month,
): MonthAccount {
    let monthAccountId = account.id.concat(month.id);
    let monthAccount = MonthAccount.load(monthAccountId);

    if (monthAccount != null) {
        return monthAccount;
    }

    month.activeAccounts = month.activeAccounts + 1;

    monthAccount = new MonthAccount(monthAccountId);
    monthAccount.account = account.id;
    monthAccount.month = month.id;

    return monthAccount;
}

export function getTotal(): Total {
    const totalId = Bytes.fromHexString('0x746f74616c');
    let total = Total.load(totalId);

    if (total !== null) {
        return total;
    }

    total = new Total(totalId);
    total.createdAccounts = 0;
    total.deployedAccounts = 0;
    total.transactions = 0;
    total.backedUp = 0;
    total.invested = ZERO;
    total.realizedGain = ZERO;
    total.gasSponsored = ZERO;

    return total;
}
