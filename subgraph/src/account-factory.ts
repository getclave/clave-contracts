/* eslint-disable @typescript-eslint/consistent-type-imports */

/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import {
    Address,
    BigInt,
    Bytes,
    ethereum,
    json,
} from '@graphprotocol/graph-ts';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { NewClaveAccount as NewClaveAccountEvent } from '../generated/AccountFactory/AccountFactory';
import { ClaveAccount } from '../generated/schema';
import { Account } from '../generated/templates';
import { wallets } from '../wallets';
import {
    ZERO,
    getOrCreateDay,
    getOrCreateMonth,
    getOrCreateWeek,
    getTotal,
} from './helpers';

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
        const day = getOrCreateDay(createdAtDate);
        const week = getOrCreateWeek(createdAtDate);
        const month = getOrCreateMonth(createdAtDate);
        const total = getTotal();

        day.createdAccounts = day.createdAccounts + 1;
        week.createdAccounts = week.createdAccounts + 1;
        month.createdAccounts = month.createdAccounts + 1;
        total.createdAccounts = total.createdAccounts + 1;
        account.creationDate = createdAtDate;
        account.hasRecovery = false;
        account.isRecovering = false;
        account.recoveryCount = 0;
        account.txCount = 0;

        day.save();
        week.save();
        month.save();
        total.save();
        account.save();
        Account.create(Address.fromBytes(Bytes.fromHexString(accountAddress)));
    });
}

export function handleNewClaveAccount(event: NewClaveAccountEvent): void {
    let account = ClaveAccount.load(event.params.accountAddress);
    const day = getOrCreateDay(event.block.timestamp);
    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();
    day.deployedAccounts = day.deployedAccounts + 1;
    week.deployedAccounts = week.deployedAccounts + 1;
    month.deployedAccounts = month.deployedAccounts + 1;
    total.deployedAccounts = total.deployedAccounts + 1;
    if (!account) {
        account = new ClaveAccount(event.params.accountAddress);

        account.hasRecovery = false;
        account.isRecovering = false;
        account.recoveryCount = 0;
        account.txCount = 0;
        account.creationDate = ZERO;
    }
    account.implementation = Bytes.fromHexString(
        '0xdd4dD37B22Fc16DBFF3daB6Ecd681798c459f275',
    );
    account.deployDate = event.block.timestamp;

    day.save();
    week.save();
    month.save();
    total.save();
    account.save();
}
