/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import {
    NewClaveAccount as NewClaveAccountEvent,
    OwnershipTransferred as OwnershipTransferredEvent,
} from '../generated/AccountFactory/AccountFactory';
import { NewClaveAccount, OwnershipTransferred } from '../generated/schema';

export function handleNewClaveAccount(event: NewClaveAccountEvent): void {
    let entity = new NewClaveAccount(
        event.transaction.hash.concatI32(event.logIndex.toI32()),
    );
    entity.accountAddress = event.params.accountAddress;

    entity.blockNumber = event.block.number;
    entity.blockTimestamp = event.block.timestamp;
    entity.transactionHash = event.transaction.hash;

    entity.save();
}

export function handleOwnershipTransferred(
    event: OwnershipTransferredEvent,
): void {
    let entity = new OwnershipTransferred(
        event.transaction.hash.concatI32(event.logIndex.toI32()),
    );
    entity.previousOwner = event.params.previousOwner;
    entity.newOwner = event.params.newOwner;

    entity.blockNumber = event.block.number;
    entity.blockTimestamp = event.block.timestamp;
    entity.transactionHash = event.transaction.hash;

    entity.save();
}
