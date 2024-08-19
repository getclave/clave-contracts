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
    Cashback,
    ClaveAccount,
    DailyEarnFlow,
    Day,
    DayAccount,
    EarnPosition,
    Month,
    MonthAccount,
    MonthlyEarnFlow,
    ReferralFee,
    Total,
    Week,
    WeekAccount,
    WeeklyEarnFlow,
} from '../generated/schema';

export const ZERO = BigInt.fromI32(0);
export const ONE = BigInt.fromI32(1);
const START_TIMESTAMP = BigInt.fromU32(1705881660);
const MONTH_START_TIMESTAMP = BigInt.fromU32(1704067260);
const DAY = BigInt.fromU32(86_400);
const WEEK = BigInt.fromU32(604_800);
const MONTH = BigInt.fromU32(2_592_000);

export function getOrCreateDay(timestamp: BigInt): Day {
    let dayNumber = timestamp.minus(START_TIMESTAMP).div(DAY);
    let dayId = Bytes.fromByteArray(
        Bytes.fromBigInt(START_TIMESTAMP.plus(dayNumber.times(DAY))),
    ).concat(Bytes.fromHexString('0x0000'));
    let day = Day.load(dayId);

    if (day !== null) {
        return day;
    }

    day = new Day(dayId);
    day.createdAccounts = 0;
    day.deployedAccounts = 0;
    day.activeAccounts = 0;
    day.transactions = 0;
    day.gasSponsored = ZERO;

    return day;
}

export function getOrCreateDayAccount(
    account: ClaveAccount,
    day: Day,
): DayAccount {
    let dayAccountId = account.id.concat(day.id);
    let dayAccount = DayAccount.load(dayAccountId);

    if (dayAccount != null) {
        return dayAccount;
    }

    day.activeAccounts = day.activeAccounts + 1;

    dayAccount = new DayAccount(dayAccountId);
    dayAccount.account = account.id;
    dayAccount.day = day.id;

    return dayAccount;
}

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
    let monthNumber = timestamp.minus(MONTH_START_TIMESTAMP).div(MONTH);
    let monthId = Bytes.fromByteArray(
        Bytes.fromBigInt(MONTH_START_TIMESTAMP.plus(monthNumber.times(MONTH))),
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
    total.gasSponsored = ZERO;

    return total;
}

export function getOrCreateEarnPosition(
    account: ClaveAccount,
    pool: Bytes,
    token: Bytes,
    protocol: string,
): EarnPosition {
    let earnPositionId = account.id.concat(pool).concat(token);
    let earnPosition = EarnPosition.load(earnPositionId);

    if (earnPosition !== null) {
        return earnPosition;
    }

    earnPosition = new EarnPosition(earnPositionId);
    earnPosition.account = account.id;
    earnPosition.pool = pool;
    earnPosition.token = token;
    earnPosition.protocol = protocol;
    earnPosition.invested = ZERO;
    earnPosition.compoundGain = ZERO;
    earnPosition.normalGain = ZERO;

    return earnPosition;
}

export function getOrCreateDailyEarnFlow(
    day: Day,
    token: Bytes,
    protocol: string,
): DailyEarnFlow {
    let dailyEarnFlowId = day.id.concat(token).concat(Bytes.fromUTF8(protocol));
    let dailyEarnFlow = DailyEarnFlow.load(dailyEarnFlowId);

    if (dailyEarnFlow !== null) {
        return dailyEarnFlow;
    }

    dailyEarnFlow = new DailyEarnFlow(dailyEarnFlowId);
    dailyEarnFlow.day = day.id;
    dailyEarnFlow.erc20 = token;
    dailyEarnFlow.protocol = protocol;
    dailyEarnFlow.amountIn = ZERO;
    dailyEarnFlow.amountOut = ZERO;
    dailyEarnFlow.claimedGain = ZERO;

    return dailyEarnFlow;
}

export function getOrCreateWeeklyEarnFlow(
    week: Week,
    token: Bytes,
    protocol: string,
): WeeklyEarnFlow {
    let weeklyEarnFlowId = week.id
        .concat(token)
        .concat(Bytes.fromUTF8(protocol));
    let weeklyEarnFlow = WeeklyEarnFlow.load(weeklyEarnFlowId);

    if (weeklyEarnFlow !== null) {
        return weeklyEarnFlow;
    }

    weeklyEarnFlow = new WeeklyEarnFlow(weeklyEarnFlowId);
    weeklyEarnFlow.week = week.id;
    weeklyEarnFlow.erc20 = token;
    weeklyEarnFlow.protocol = protocol;
    weeklyEarnFlow.amountIn = ZERO;
    weeklyEarnFlow.amountOut = ZERO;
    weeklyEarnFlow.claimedGain = ZERO;

    return weeklyEarnFlow;
}

export function getOrCreateMonthlyEarnFlow(
    month: Month,
    token: Bytes,
    protocol: string,
): MonthlyEarnFlow {
    let monthlyEarnFlowId = month.id
        .concat(token)
        .concat(Bytes.fromUTF8(protocol));
    let monthlyEarnFlow = MonthlyEarnFlow.load(monthlyEarnFlowId);

    if (monthlyEarnFlow !== null) {
        return monthlyEarnFlow;
    }

    monthlyEarnFlow = new MonthlyEarnFlow(monthlyEarnFlowId);
    monthlyEarnFlow.month = month.id;
    monthlyEarnFlow.erc20 = token;
    monthlyEarnFlow.protocol = protocol;
    monthlyEarnFlow.amountIn = ZERO;
    monthlyEarnFlow.amountOut = ZERO;
    monthlyEarnFlow.claimedGain = ZERO;

    return monthlyEarnFlow;
}

export function getOrCreateCashback(
    account: ClaveAccount,
    token: Bytes,
): Cashback {
    let cashbackId = account.id
        .concat(token)
        .concat(Bytes.fromHexString('0xcb'));
    let cashback = Cashback.load(cashbackId);

    if (cashback !== null) {
        return cashback;
    }

    cashback = new Cashback(cashbackId);
    cashback.account = account.id;
    cashback.erc20 = token;
    cashback.amount = ZERO;

    return cashback;
}

export function getOrCreateReferralFee(
    referrer: ClaveAccount,
    referred: ClaveAccount,
    token: Bytes,
): ReferralFee {
    let referralFeeId = referrer.id.concat(referred.id).concat(token);

    let referralFee = ReferralFee.load(referralFeeId);

    if (referralFee !== null) {
        return referralFee;
    }

    referralFee = new ReferralFee(referralFeeId);
    referralFee.account = referrer.id;
    referralFee.referred = referred.id;
    referralFee.erc20 = token;
    referralFee.amount = ZERO;

    return referralFee;
}
