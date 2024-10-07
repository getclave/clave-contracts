/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { assert, expect } from 'chai';
import type { ec } from 'elliptic';
import type { HDNodeWallet } from 'ethers';
import { parseEther } from 'ethers';
import * as hre from 'hardhat';
import { Provider, Wallet, utils } from 'zksync-ethers';
import type { Contract } from 'zksync-ethers';
import type { TransactionLike } from 'zksync-ethers/build/types';

import { LOCAL_RICH_WALLETS, getWallet } from '../../../deploy/utils';
import { ClaveDeployer } from '../../utils/deployer';
import { fixture } from '../../utils/fixture';
import { addK1Key } from '../../utils/managers/ownermanager';
import { addK1Validator } from '../../utils/managers/validatormanager';
import { VALIDATORS } from '../../utils/names';
import {
    ethTransfer,
    prepareEOATx,
    prepareMockTx,
} from '../../utils/transactions';

describe('Clave Contracts - Validator tests', () => {
    let deployer: ClaveDeployer;
    let provider: Provider;
    let richWallet: Wallet;
    let teeValidator: Contract;
    let account: Contract;
    let keyPair: ec.KeyPair;

    before(async () => {
        richWallet = getWallet(hre, LOCAL_RICH_WALLETS[0].privateKey);
        deployer = new ClaveDeployer(hre, richWallet);
        provider = new Provider(hre.network.config.url, undefined, {
            cacheTimeout: -1,
        });

        [, , , , teeValidator, account, keyPair] = await fixture(
            deployer,
            VALIDATORS.TEE,
        );

        const accountAddress = await account.getAddress();

        await deployer.fund(10000, accountAddress);
    });

    describe('EOAValidator', () => {
        let newK1Validator: Contract;
        let newK1Owner: HDNodeWallet;

        before(async () => {
            newK1Validator = await deployer.validator(VALIDATORS.EOA);
            newK1Owner = Wallet.createRandom();

            await addK1Validator(
                provider,
                account,
                teeValidator,
                newK1Validator,
                keyPair,
            );

            await addK1Key(
                provider,
                account,
                teeValidator,
                await newK1Owner.getAddress(),
                keyPair,
            );
        });

        it('should check existing validator', async () => {
            const teeValidatorAddress = await teeValidator.getAddress();
            const k1ValidatorAddress = await newK1Validator.getAddress();
            const k1OwnerAddress = await newK1Owner.getAddress();

            expect(await account.r1IsValidator(teeValidatorAddress)).to.be.true;

            expect(await account.k1IsValidator(k1ValidatorAddress)).to.be.true;

            expect(await account.k1IsOwner(k1OwnerAddress)).to.be.true;
        });

        describe('Signature checks', () => {
            let richAddress: string;
            let richBalanceBefore: bigint;
            let amount: bigint;

            let txData: TransactionLike;

            beforeEach(async () => {
                richBalanceBefore = await provider.getBalance(richAddress);
            });

            before(async () => {
                richAddress = await richWallet.getAddress();

                amount = parseEther('1');

                txData = ethTransfer(richAddress, amount);
            });

            describe('Valid tx and signature', () => {
                it('should send a tx', async () => {
                    const tx = await prepareEOATx(
                        provider,
                        account,
                        txData,
                        await newK1Validator.getAddress(),
                        newK1Owner,
                    );
                    const txReceipt = await provider.broadcastTransaction(
                        utils.serializeEip712(tx),
                    );
                    await txReceipt.wait();

                    const richBalanceAfter = await provider.getBalance(
                        richAddress,
                    );
                    expect(richBalanceAfter).to.eq(richBalanceBefore + amount);
                });
            });

            describe('Invalid tx and signature', () => {
                it('should revert sending the tx', async () => {
                    const mockTxData = txData;
                    mockTxData.to = await Wallet.createRandom().getAddress(); // corrupted tx data

                    const tx = await prepareEOATx(
                        provider,
                        account,
                        txData,
                        await newK1Validator.getAddress(),
                        newK1Owner,
                    );

                    try {
                        const txReceipt = await provider.broadcastTransaction(
                            utils.serializeEip712(tx),
                        );
                        await txReceipt.wait();
                        assert(false);
                    } catch (err) {}

                    const richBalanceAfter = await provider.getBalance(
                        richAddress,
                    );
                    expect(richBalanceAfter).to.eq(richBalanceBefore);
                });
            });

            describe('Tx and wrong signature', () => {
                it('should revert sending the tx', async () => {
                    const tx = await prepareMockTx(
                        provider,
                        account,
                        txData,
                        await newK1Validator.getAddress(),
                    );

                    try {
                        const txReceipt = await provider.broadcastTransaction(
                            utils.serializeEip712(tx),
                        );
                        await txReceipt.wait();
                        assert(false);
                    } catch (err) {}

                    const richBalanceAfter = await provider.getBalance(
                        richAddress,
                    );
                    expect(richBalanceAfter).to.eq(richBalanceBefore);
                });
            });
        });
    });
});
