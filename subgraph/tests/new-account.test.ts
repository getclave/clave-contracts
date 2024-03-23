/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Address } from '@graphprotocol/graph-ts';
import {
    afterAll,
    assert,
    beforeAll,
    clearStore,
    describe,
    test,
} from 'matchstick-as/assembly/index';

import { handleNewClaveAccount } from '../src/account-factory';
import { createNewClaveAccountEvent } from './new-account-utils';

describe('handleNewClaveAccount()', () => {
    beforeAll(() => {
        const accountAddress = Address.fromString(
            '0x0000000000000000000000000000000000000001',
        );
        const newClaveAccountEvent = createNewClaveAccountEvent(accountAddress);
        handleNewClaveAccount(newClaveAccountEvent);
    });

    afterAll(() => {
        clearStore();
    });

    test('ClaveAccount created and stored', () => {
        assert.entityCount('ClaveAccount', 1);
        assert.fieldEquals(
            'ClaveAccount',
            '0x0000000000000000000000000000000000000001',
            'id',
            '0x0000000000000000000000000000000000000001',
        );
    });
});
