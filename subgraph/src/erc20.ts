/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { Transfer as TransferEvent } from '../generated/erc20/ERC20';
import { ClaveAccount, Token } from '../generated/schema';
import {
    decreaseAccountBalance,
    fetchTokenDecimals,
    fetchTokenName,
    fetchTokenSymbol,
    increaseAccountBalance,
    toDecimal,
} from './helpers';

export function handleTransfer(event: TransferEvent): void {
    const from = event.params.from;
    const to = event.params.to;

    const fromAccount = ClaveAccount.load(from);
    const toAccount = ClaveAccount.load(to);

    //not a Clave related transfer
    if (fromAccount === null && toAccount === null) {
        return;
    }

    const tokenAddress = event.address;
    let token = Token.load(tokenAddress);
    if (!token) {
        token = new Token(tokenAddress);
        token.name = fetchTokenName(tokenAddress);
        token.symbol = fetchTokenSymbol(tokenAddress);
        token.decimals = fetchTokenDecimals(tokenAddress) as i32;
    }
    token.save();

    const amount = toDecimal(event.params.value, token.decimals);
    if (fromAccount !== null) {
        const tokenBalanceFrom = decreaseAccountBalance(
            fromAccount,
            token,
            amount,
        );
        tokenBalanceFrom.save();
    }
    if (toAccount !== null) {
        const tokenBalanceTo = increaseAccountBalance(toAccount, token, amount);
        tokenBalanceTo.save();
    }
}
