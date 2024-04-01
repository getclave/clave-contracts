/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
/* eslint-disable @typescript-eslint/consistent-type-imports */
import { Swap as SwapEvent } from '../generated/OdosRouter/OdosRouter';
import { ClaveAccount, InAppSwap } from '../generated/schema';

export function handleSwap(event: SwapEvent): void {
    const inAppSwap = new InAppSwap(
        event.transaction.hash.concatI32(event.logIndex.toI32()),
    );

    const account = ClaveAccount.load(event.params.sender);

    if (!account) {
        return;
    }

    inAppSwap.account = account.id;
    inAppSwap.amountIn = event.params.inputAmount;
    inAppSwap.tokenIn = event.params.inputToken;
    inAppSwap.amountOut = event.params.amountOut;
    inAppSwap.tokenOut = event.params.outputToken;
    inAppSwap.date = event.block.timestamp;

    inAppSwap.save();
}
