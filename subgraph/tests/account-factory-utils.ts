/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Address, ethereum } from '@graphprotocol/graph-ts';
import { newMockEvent } from 'matchstick-as';

import {
    NewClaveAccount,
    OwnershipTransferred,
} from '../generated/AccountFactory/AccountFactory';

export function createNewClaveAccountEvent(
    accountAddress: Address,
): NewClaveAccount {
    let newClaveAccountEvent = changetype<NewClaveAccount>(newMockEvent());

    newClaveAccountEvent.parameters = new Array();

    newClaveAccountEvent.parameters.push(
        new ethereum.EventParam(
            'accountAddress',
            ethereum.Value.fromAddress(accountAddress),
        ),
    );

    return newClaveAccountEvent;
}

export function createOwnershipTransferredEvent(
    previousOwner: Address,
    newOwner: Address,
): OwnershipTransferred {
    let ownershipTransferredEvent = changetype<OwnershipTransferred>(
        newMockEvent(),
    );

    ownershipTransferredEvent.parameters = new Array();

    ownershipTransferredEvent.parameters.push(
        new ethereum.EventParam(
            'previousOwner',
            ethereum.Value.fromAddress(previousOwner),
        ),
    );
    ownershipTransferredEvent.parameters.push(
        new ethereum.EventParam(
            'newOwner',
            ethereum.Value.fromAddress(newOwner),
        ),
    );

    return ownershipTransferredEvent;
}
