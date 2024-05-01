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
import { ZERO, getOrCreateWeek } from './helpers';

export function handleClaveAccountCreated(
    event: ClaveAccountCreatedEvent,
): void {
    let account = ClaveAccount.load(event.params.accountAddress);
    if (account) {
        return;
    }
    account = new ClaveAccount(event.params.accountAddress);
    const week = getOrCreateWeek(event.block.timestamp);

    week.createdAccounts = week.createdAccounts + 1;
    account.creationDate = event.block.timestamp;
    account.hasRecovery = false;
    account.isRecovering = false;
    account.recoveryCount = 0;

    week.save();
    account.save();
}

export function handleClaveAccountDeployed(
    event: ClaveAccountDeployedEvent,
): void {
    let account = ClaveAccount.load(event.params.accountAddress);
    const week = getOrCreateWeek(event.block.timestamp);
    week.deployedAccounts = week.deployedAccounts + 1;
    if (!account) {
        account = new ClaveAccount(event.params.accountAddress);

        account.hasRecovery = false;
        account.isRecovering = false;
        account.recoveryCount = 0;
        account.creationDate = ZERO;
    }

    account.implementation = Bytes.fromHexString(
        '0xf5bEDd0304ee359844541262aC349a6016A50bc6',
    );
    account.deployDate = event.block.timestamp;

    week.save();
    account.save();
}
