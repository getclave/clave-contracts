import { Supply, Withdraw } from '../generated/schema';
import {
    Supply as SupplyEvent,
    Withdraw as WithdrawEvent,
} from '../generated/zeroUsdtPool/zeroUsdtPool';

export function handleSupply(event: SupplyEvent): void {
    let entity = new Supply(
        event.transaction.hash.concatI32(event.logIndex.toI32()),
    );
    entity.reserve = event.params.reserve;
    entity.user = event.params.user;
    entity.onBehalfOf = event.params.onBehalfOf;
    entity.amount = event.params.amount;
    entity.referralCode = event.params.referralCode;

    entity.blockNumber = event.block.number;
    entity.blockTimestamp = event.block.timestamp;
    entity.transactionHash = event.transaction.hash;

    entity.save();
}

export function handleWithdraw(event: WithdrawEvent): void {
    let entity = new Withdraw(
        event.transaction.hash.concatI32(event.logIndex.toI32()),
    );
    entity.reserve = event.params.reserve;
    entity.user = event.params.user;
    entity.to = event.params.to;
    entity.amount = event.params.amount;

    entity.blockNumber = event.block.number;
    entity.blockTimestamp = event.block.timestamp;
    entity.transactionHash = event.transaction.hash;

    entity.save();
}
