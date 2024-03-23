/* eslint-disable @typescript-eslint/consistent-type-imports */

/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Address, ethereum } from '@graphprotocol/graph-ts';
import { newMockEvent } from 'matchstick-as';

import { NewClaveAccount } from '../generated/AccountFactory/AccountFactory';
import { Transfer } from '../generated/erc20/ERC20';

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

export function createNewTransferEvent(
    from: Address,
    to: Address,
    value: ethereum.Value,
): Transfer {
    const newTransferEvent = changetype<Transfer>(newMockEvent());
    newTransferEvent.parameters = [];

    newTransferEvent.parameters.push(
        new ethereum.EventParam('from', ethereum.Value.fromAddress(from)),
    );
    newTransferEvent.parameters.push(
        new ethereum.EventParam('to', ethereum.Value.fromAddress(to)),
    );
    newTransferEvent.parameters.push(new ethereum.EventParam('value', value));

    return newTransferEvent;
}
