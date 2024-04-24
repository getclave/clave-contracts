/* eslint-disable @typescript-eslint/ban-types */

/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */

/* eslint-disable prefer-const */
import { Address, Bytes } from '@graphprotocol/graph-ts';
import { BigInt } from '@graphprotocol/graph-ts';

import { ERC20 as ERC20Class } from '../generated/erc20/ERC20';
import {
    ClaveAccount,
    ERC20,
    ERC20Balance,
    Week,
    WeekAccount,
} from '../generated/schema';

const DEFAULT_DECIMALS = 18;

export const ZERO = BigInt.fromI32(0);
export const ONE = BigInt.fromI32(1);
const START_TIMESTAMP = BigInt.fromU32(1706045075);
const WEEK = BigInt.fromU32(604_800);

export function fetchTokenSymbol(tokenAddress: Address): string {
    let contract = ERC20Class.bind(tokenAddress);

    // try types string and bytes32 for symbol
    let symbolValue = 'unknown';
    let symbolResult = contract.try_symbol();
    if (!symbolResult.reverted) {
        symbolValue = symbolResult.value;
    }

    return symbolValue;
}

export function fetchTokenName(tokenAddress: Address): string {
    let contract = ERC20Class.bind(tokenAddress);

    let nameValue = 'unknown';
    let nameResult = contract.try_name();
    if (!nameResult.reverted) {
        nameValue = nameResult.value;
    }

    return nameValue;
}

// eslint-disable-next-line @typescript-eslint/ban-types
export function fetchTokenDecimals(tokenAddress: Address): number {
    let contract = ERC20Class.bind(tokenAddress);
    // try types uint8 for decimals
    let decimalValue = DEFAULT_DECIMALS;
    let decimalResult = contract.try_decimals();
    if (!decimalResult.reverted) {
        decimalValue = decimalResult.value;
    }
    return decimalValue;
}

function getOrCreateAccountBalance(
    account: ClaveAccount,
    token: ERC20,
): ERC20Balance {
    let balanceId = account.id.concat(token.id);
    let previousBalance = ERC20Balance.load(balanceId);

    if (previousBalance !== null) {
        return previousBalance;
    }

    let newBalance = new ERC20Balance(balanceId);
    newBalance.account = account.id;
    newBalance.token = token.id;
    newBalance.amount = ZERO;

    return newBalance;
}

export function increaseAccountBalance(
    account: ClaveAccount,
    token: ERC20,
    amount: BigInt,
): ERC20Balance {
    let balance = getOrCreateAccountBalance(account, token);
    balance.amount = balance.amount.plus(amount);
    token.totalAmount = token.totalAmount.plus(amount);
    token.save();

    return balance;
}

export function decreaseAccountBalance(
    account: ClaveAccount,
    token: ERC20,
    amount: BigInt,
): ERC20Balance {
    let balance = getOrCreateAccountBalance(account, token);
    balance.amount = balance.amount.minus(amount);
    token.totalAmount = token.totalAmount.minus(amount);
    token.save();

    return balance;
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
