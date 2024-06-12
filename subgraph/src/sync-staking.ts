/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
/* eslint-disable @typescript-eslint/consistent-type-imports */
import { ClaimRewards as ClaimRewardsEvent } from '../generated/SyncStaking/SyncStaking';
import { ClaveAccount } from '../generated/schema';
import {
    getOrCreateDay,
    getOrCreateMonth,
    getOrCreateWeek,
    getTotal,
} from './helpers';

export function handleClaimRewards(event: ClaimRewardsEvent): void {
    const account = ClaveAccount.load(event.params.from);
    if (!account) {
        return;
    }

    const amount = event.params.amount;

    const day = getOrCreateDay(event.block.timestamp);
    const week = getOrCreateWeek(event.block.timestamp);
    const month = getOrCreateMonth(event.block.timestamp);
    const total = getTotal();

    day.realizedGainEth = day.realizedGainEth.plus(amount);
    week.realizedGainEth = week.realizedGainEth.plus(amount);
    month.realizedGainEth = month.realizedGainEth.plus(amount);
    total.realizedGainEth = total.realizedGainEth.plus(amount);
    account.realizedGainEth = account.realizedGainEth.plus(amount);

    day.save();
    week.save();
    month.save();
    total.save();
    account.save();
}
