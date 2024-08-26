/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import { Bytes } from '@graphprotocol/graph-ts';

import {
    ClaveAccountCreated as ClaveAccountCreatedEvent,
    ClaveAccountDeployed as ClaveAccountDeployedEvent,
} from '../generated/Contract/Contract';
import { ClaveAccount } from '../generated/schema';
import { Account } from '../generated/templates';
import { ZERO, getOrCreateMonth, getOrCreateWeek, getTotal } from './helpers';

export function handleClaveAccountCreated(
    event: ClaveAccountCreatedEvent,
): void {
    let account = ClaveAccount.load(event.params.accountAddress);
    if (account) {
        return;
    }
    account = new ClaveAccount(event.params.accountAddress);
    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();

    week.createdAccounts = week.createdAccounts + 1;
    month.createdAccounts = month.createdAccounts + 1;
    total.createdAccounts = total.createdAccounts + 1;
    account.creationDate = event.block.timestamp;
    account.hasRecovery = false;
    account.isRecovering = false;
    account.recoveryCount = 0;
    account.txCount = 0;
    account.invested = ZERO;
    account.realizedGain = ZERO;

    week.save();
    month.save();
    total.save();
    account.save();
    Account.create(event.params.accountAddress);
}

export function handleClaveAccountDeployed(
    event: ClaveAccountDeployedEvent,
): void {
    let account = ClaveAccount.load(event.params.accountAddress);
    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();
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
        account.invested = ZERO;
        account.realizedGain = ZERO;
    }

    account.implementationAddress = Bytes.fromHexString(
        '0xf5bEDd0304ee359844541262aC349a6016A50bc6',
    );
    account.deployDate = event.block.timestamp;

    week.save();
    month.save();
    total.save();
    account.save();
}
