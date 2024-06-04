/* eslint-disable @typescript-eslint/ban-types */

/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */

/* eslint-disable prefer-const */
import { BigInt } from '@graphprotocol/graph-ts';

import { ClaveAccount, ERC20, ERC20Balance } from '../generated/schema';

export const ZERO = BigInt.fromI32(0);
export const ONE = BigInt.fromI32(1);

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
