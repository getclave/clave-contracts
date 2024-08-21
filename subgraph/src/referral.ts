/* eslint-disable @typescript-eslint/consistent-type-imports */

/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import {
    Cashback as CashbackEvent,
    ReferralFee as ReferralFeeEvent,
} from '../generated/SwapReferralFeePayer/SwapReferralFeePayer';
import { ClaveAccount } from '../generated/schema';
import { getOrCreateCashback, getOrCreateReferralFee } from './helpers';

export function handleCashback(event: CashbackEvent): void {
    const account = ClaveAccount.load(event.params.referred);
    if (!account) {
        return;
    }

    const cashback = getOrCreateCashback(account, event.params.token);
    cashback.amount = cashback.amount.plus(event.params.fee);
    cashback.save();
}

export function handleReferralFee(event: ReferralFeeEvent): void {
    const referrer = ClaveAccount.load(event.params.referrer);
    if (!referrer) {
        return;
    }

    const referred = ClaveAccount.load(event.transaction.from);
    if (!referred) {
        return;
    }

    const referralFee = getOrCreateReferralFee(
        referrer,
        referred,
        event.params.token,
    );
    referralFee.amount = referralFee.amount.plus(event.params.fee);
    referralFee.save();
}
