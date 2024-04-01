/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
/* eslint-disable @typescript-eslint/consistent-type-imports */
import { BigInt, store } from '@graphprotocol/graph-ts';

import {
    FeePaid as FeePaidEvent,
    K1AddOwner as K1AddOwnerEvent,
    K1RemoveOwner as K1RemoveOwnerEvent,
    R1AddOwner as R1AddOwnerEvent,
    R1RemoveOwner as R1RemoveOwnerEvent,
    ResetOwners as ResetOwnersEvent,
    Upgraded as UpgradedEvent,
} from '../generated/ClaveImplementation/ClaveImplementation';
import { ClaveAccount, ClaveTransaction, Owner } from '../generated/schema';

export function handleFeePaid(event: FeePaidEvent): void {
    const transaction = new ClaveTransaction(event.transaction.hash);
    transaction.sender = event.address;
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    transaction.to = event.transaction.to!;
    transaction.value = event.transaction.value;
    let gasUsed = BigInt.fromI32(0);
    const receipt = event.receipt;
    if (receipt != null) {
        gasUsed = receipt.gasUsed;
    }
    transaction.gasCost = event.transaction.gasPrice.times(gasUsed);
    transaction.paymaster = 'None';
    transaction.date = event.block.timestamp;

    transaction.save();
}

export function handleK1AddOwner(event: K1AddOwnerEvent): void {
    const owner = new Owner(event.address.concat(event.params.addr));

    owner.account = event.address;
    owner.ownerType = 'Address';
    owner.owner = event.params.addr;
    owner.dateAdded = event.block.timestamp;

    owner.save();
}

export function handleK1RemoveOwner(event: K1RemoveOwnerEvent): void {
    store.remove('Owner', event.address.concat(event.params.addr).toString());
}

export function handleR1AddOwner(event: R1AddOwnerEvent): void {
    const owner = new Owner(event.address.concat(event.params.pubKey));

    owner.account = event.address;
    owner.ownerType = 'PublicKey';
    owner.owner = event.params.pubKey;
    owner.dateAdded = event.block.timestamp;

    owner.save();
}

export function handleR1RemoveOwner(event: R1RemoveOwnerEvent): void {
    store.remove('Owner', event.address.concat(event.params.pubKey).toString());
}

export function handleResetOwners(event: ResetOwnersEvent): void {
    const account = ClaveAccount.load(event.address);
    if (account == null) {
        return;
    }
    const owners = account.owners.load();
    if (owners == null) {
        return;
    }
    for (let i = 0; i < owners.length; i++) {
        store.remove('Owner', event.address.concat(owners[i].owner).toString());
    }
}

export function handleUpgraded(event: UpgradedEvent): void {
    const account = ClaveAccount.load(event.address);
    if (account == null) {
        return;
    }
    account.implementation = event.params.newImplementation;
    account.save();
}
