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

export function handleClaveAccountCreated(
    event: ClaveAccountCreatedEvent,
): void {
    const account = new ClaveAccount(event.params.accountAddress);

    account.creationDate = event.block.timestamp;
    account.implementation = Bytes.fromHexString(
        '0xf5bEDd0304ee359844541262aC349a6016A50bc6',
    );
    account.hasRecovery = false;
    account.isRecovering = false;
    account.recoveryCount = 0;

    account.save();
}

export function handleClaveAccountDeployed(
    event: ClaveAccountDeployedEvent,
): void {
    let account = ClaveAccount.load(event.params.accountAddress);
    if (!account) {
        account = new ClaveAccount(event.params.accountAddress);

        account.implementation = Bytes.fromHexString(
            '0xf5bEDd0304ee359844541262aC349a6016A50bc6',
        );
        account.hasRecovery = false;
        account.isRecovering = false;
        account.recoveryCount = 0;
    }

    account.deployDate = event.block.timestamp;

    account.save();
}
