/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */

/* eslint-disable prefer-const */
// import { Address } from '@graphprotocol/graph-ts';
// import { BigDecimal, BigInt } from '@graphprotocol/graph-ts';

// import { ERC20 } from '../generated/erc20/ERC20';
// import { ClaveAccount, Token, TokenBalance } from '../generated/schema';

// const DEFAULT_DECIMALS = 18;

// export const ZERO = BigInt.fromI32(0);
// export const ONE = BigInt.fromI32(1);

// // eslint-disable-next-line @typescript-eslint/ban-types
// export function toDecimal(value: BigInt, decimals: u32): BigDecimal {
//     let precision = BigInt.fromI32(10)
//         .pow(decimals as u8)
//         .toBigDecimal();

//     let decimal = value.divDecimal(precision);

//     return decimal;
// }

// export function fetchTokenSymbol(tokenAddress: Address): string {
//     let contract = ERC20.bind(tokenAddress);

//     // try types string and bytes32 for symbol
//     let symbolValue = 'unknown';
//     let symbolResult = contract.try_symbol();
//     if (!symbolResult.reverted) {
//         symbolValue = symbolResult.value;
//     }

//     return symbolValue;
// }

// export function fetchTokenName(tokenAddress: Address): string {
//     let contract = ERC20.bind(tokenAddress);

//     let nameValue = 'unknown';
//     let nameResult = contract.try_name();
//     if (!nameResult.reverted) {
//         nameValue = nameResult.value;
//     }

//     return nameValue;
// }

// // eslint-disable-next-line @typescript-eslint/ban-types
// export function fetchTokenDecimals(tokenAddress: Address): number {
//     let contract = ERC20.bind(tokenAddress);
//     // try types uint8 for decimals
//     let decimalValue = DEFAULT_DECIMALS;
//     let decimalResult = contract.try_decimals();
//     if (!decimalResult.reverted) {
//         decimalValue = decimalResult.value;
//     }
//     return decimalValue;
// }

// function getOrCreateAccountBalance(
//     account: ClaveAccount,
//     token: Token,
// ): TokenBalance {
//     let balanceId = account.id.concat(token.id);
//     let previousBalance = TokenBalance.load(balanceId);

//     if (previousBalance !== null) {
//         return previousBalance;
//     }

//     let newBalance = new TokenBalance(balanceId);
//     newBalance.account = account.id;
//     newBalance.token = token.id;
//     newBalance.amount = BigDecimal.zero();

//     return newBalance;
// }

// export function increaseAccountBalance(
//     account: ClaveAccount,
//     token: Token,
//     amount: BigDecimal,
// ): TokenBalance {
//     let balance = getOrCreateAccountBalance(account, token);
//     balance.amount = balance.amount.plus(amount);

//     return balance;
// }

// export function decreaseAccountBalance(
//     account: ClaveAccount,
//     token: Token,
//     amount: BigDecimal,
// ): TokenBalance {
//     let balance = getOrCreateAccountBalance(account, token);
//     balance.amount = balance.amount.minus(amount);

//     return balance;
// }
