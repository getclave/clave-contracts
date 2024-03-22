/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { NewClaveAccount as NewClaveAccountEvent } from '../generated/AccountFactory/AccountFactory';
import { ClaveAccount } from '../generated/schema';

export function handleNewClaveAccount(event: NewClaveAccountEvent): void {
    const account = new ClaveAccount(event.params.accountAddress);

    account.deployDate = event.block.timestamp;

    account.save();
}
