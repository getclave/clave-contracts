/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { NewClaveAccount as NewClaveAccountEvent } from '../generated/AccountFactory/AccountFactory';
import { NewClaveAccount } from '../generated/schema';

export function handleNewClaveAccount(event: NewClaveAccountEvent): void {
    const entity = new NewClaveAccount(
        event.transaction.hash.concatI32(event.logIndex.toI32()),
    );
    entity.accountAddress = event.params.accountAddress;

    entity.blockNumber = event.block.number;
    entity.blockTimestamp = event.block.timestamp;
    entity.transactionHash = event.transaction.hash;

    entity.save();
}
