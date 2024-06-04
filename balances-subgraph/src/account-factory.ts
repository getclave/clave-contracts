/* eslint-disable @typescript-eslint/consistent-type-imports */

/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Bytes, ethereum, json } from '@graphprotocol/graph-ts';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ClaveAccountCreated as ClaveAccountCreatedEvent } from '../generated/AccountFactory/AccountFactory';
import { ClaveAccount } from '../generated/schema';
import { wallets } from '../wallets';

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export function handleOnce(_block: ethereum.Block): void {
    const walletsJson = json.fromString(wallets).toArray();
    walletsJson.forEach((element) => {
        const accountAddress = element.toObject().entries[0].value.toString();
        const account = new ClaveAccount(Bytes.fromHexString(accountAddress));

        account.save();
    });
}

export function handleClaveAccountCreated(
    event: ClaveAccountCreatedEvent,
): void {
    const account = new ClaveAccount(event.params.accountAddress);
    account.save();
}
