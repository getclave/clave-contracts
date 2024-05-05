/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { Transfer as TransferEvent } from '../generated/erc20/ERC20';
import { ClaveAccount, ERC20 } from '../generated/schema';
import {
    ZERO,
    decreaseAccountBalance,
    increaseAccountBalance,
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
    let token = ERC20.load(tokenAddress);
    if (!token) {
        token = new ERC20(tokenAddress);
        token.totalAmount = ZERO;
    }

    const amount = event.params.value;
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
