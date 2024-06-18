/* eslint-disable @typescript-eslint/consistent-type-imports */

/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Address, ethereum } from '@graphprotocol/graph-ts';
import { newMockEvent } from 'matchstick-as';

import { NewClaveAccount } from '../generated/AccountFactory/AccountFactory';

export function createNewClaveAccountEvent(
    accountAddress: Address,
): NewClaveAccount {
    const newClaveAccountEvent = changetype<NewClaveAccount>(newMockEvent());
    newClaveAccountEvent.parameters = [];

    newClaveAccountEvent.parameters.push(
        new ethereum.EventParam(
            'accountAddress',
            ethereum.Value.fromAddress(accountAddress),
        ),
    );

    return newClaveAccountEvent;
}
