/* eslint-disable @typescript-eslint/consistent-type-imports */

/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { BigInt, Bytes, ethereum, json } from '@graphprotocol/graph-ts';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { NewClaveAccount as NewClaveAccountEvent } from '../generated/AccountFactory/AccountFactory';
import { ClaveAccount } from '../generated/schema';
import { wallets } from '../wallets';
import { getOrCreateWeek } from './helpers';

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export function handleOnce(_block: ethereum.Block): void {
    const walletsJson = json.fromString(wallets).toArray();
    walletsJson.forEach((element) => {
        const accountAddress = element.toObject().entries[0].value.toString();
        const createdAt = element.toObject().entries[1].value.toString();
        const createdAtDate = BigInt.fromI64(
            Date.parse(createdAt).getTime(),
        ).div(BigInt.fromU32(1000));
        const account = new ClaveAccount(Bytes.fromHexString(accountAddress));
        const week = getOrCreateWeek(createdAtDate);

        week.createdAccounts = week.createdAccounts + 1;
        account.creationDate = createdAtDate;
        account.hasRecovery = false;
        account.isRecovering = false;
        account.recoveryCount = 0;

        week.save();
        account.save();
    });
}

export function handleNewClaveAccount(event: NewClaveAccountEvent): void {
    let account = ClaveAccount.load(event.params.accountAddress);
    const week = getOrCreateWeek(event.block.timestamp);
    week.deployedAccounts = week.deployedAccounts + 1;
    if (!account) {
        account = new ClaveAccount(event.params.accountAddress);

        account.hasRecovery = false;
        account.isRecovering = false;
        account.recoveryCount = 0;
    }
    account.implementation = Bytes.fromHexString(
        '0xdd4dD37B22Fc16DBFF3daB6Ecd681798c459f275',
    );
    account.deployDate = event.block.timestamp;

    week.save();
    account.save();
}
