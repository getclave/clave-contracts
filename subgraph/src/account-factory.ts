/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Bytes } from '@graphprotocol/graph-ts';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { NewClaveAccount as NewClaveAccountEvent } from '../generated/AccountFactory/AccountFactory';
import { ClaveAccount } from '../generated/schema';

export function handleNewClaveAccount(event: NewClaveAccountEvent): void {
    const account = new ClaveAccount(event.params.accountAddress);

    account.deployDate = event.block.timestamp;
    account.hasRecovery = false;
    account.isRecovering = false;
    account.recoveryCount = 0;
    account.implementation = Bytes.fromHexString(
        '0xdd4dD37B22Fc16DBFF3daB6Ecd681798c459f275',
    );

    account.save();
}
