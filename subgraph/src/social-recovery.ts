/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

/* eslint-disable @typescript-eslint/consistent-type-imports */
import {
    Disabled as DisabledEvent,
    Inited as InitedEvent,
    RecoveryExecuted as RecoveryExecutedEvent,
    RecoveryStarted as RecoveryStartedEvent,
    RecoveryStopped as RecoveryStoppedEvent,
} from '../generated/SocialRecovery/SocialRecovery';
import { ClaveAccount } from '../generated/schema';
import { getTotal } from './helpers';

export function handleDisabled(event: DisabledEvent): void {
    const account = ClaveAccount.load(event.params.account);

    if (account === null) {
        return;
    }

    const total = getTotal();
    total.backedUp = total.backedUp - 1;

    account.hasRecovery = false;
    account.isRecovering = false;

    total.save();
    account.save();
}

export function handleInited(event: InitedEvent): void {
    const account = ClaveAccount.load(event.params.account);

    if (account === null) {
        return;
    }

    const total = getTotal();
    total.backedUp = total.backedUp + 1;

    account.hasRecovery = true;
    account.isRecovering = false;

    total.save();
    account.save();
}

export function handleRecoveryExecuted(event: RecoveryExecutedEvent): void {
    const account = ClaveAccount.load(event.params.account);

    if (account === null) {
        return;
    }

    account.isRecovering = false;
    // eslint-disable-next-line @typescript-eslint/restrict-plus-operands
    account.recoveryCount = account.recoveryCount + 1;

    account.save();
}

export function handleRecoveryStarted(event: RecoveryStartedEvent): void {
    const account = ClaveAccount.load(event.params.account);

    if (account === null) {
        return;
    }

    account.isRecovering = true;

    account.save();
}

export function handleRecoveryStopped(event: RecoveryStoppedEvent): void {
    const account = ClaveAccount.load(event.params.account);

    if (account === null) {
        return;
    }

    account.isRecovering = false;

    account.save();
}
