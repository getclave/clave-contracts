/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { assert, expect } from 'chai';
import type { ec } from 'elliptic';
import { parseEther } from 'ethers';
import * as hre from 'hardhat';
import { Contract, Provider, Wallet, utils } from 'zksync-ethers';

import { LOCAL_RICH_WALLETS, getWallet } from '../../../deploy/utils';
import { ClaveDeployer } from '../../utils/deployer';
import { fixture } from '../../utils/fixture';
import {
    addK1Validator,
    addR1Validator,
    removeK1Validator,
    removeR1Validator,
} from '../../utils/managers/validatormanager';
import { VALIDATORS } from '../../utils/names';
import { ethTransfer, prepareMockTx } from '../../utils/transactions';

describe('Clave Contracts - Manager tests', () => {
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

    describe('Validator Manager', () => {
        it('should check existing validator', async () => {
            const validatorAddress = await teeValidator.getAddress();

            expect(await account.r1IsValidator(validatorAddress)).to.be.true;
        });

        describe('Full tests with r1 validator type, adding-removing-validating', () => {
            let newR1Validator: Contract;

            it('should add a new r1 validator', async () => {
                newR1Validator = await deployer.validator(VALIDATORS.MOCK);
                const validatorAddress = await newR1Validator.getAddress();

                expect(await account.r1IsValidator(validatorAddress)).to.be
                    .false;

                await addR1Validator(
                    provider,
                    account,
                    teeValidator,
                    newR1Validator,
                    keyPair,
                );

                expect(await account.r1IsValidator(validatorAddress)).to.be
                    .true;

                const expectedValidators = [
                    validatorAddress,
                    await teeValidator.getAddress(),
                ];

                expect(await account.r1ListValidators()).to.deep.eq(
                    expectedValidators,
                );
            });

            it('should send a tx with the new r1 validator', async () => {
                const amount = parseEther('1');
                const richAddress = await richWallet.getAddress();
                const richBalanceBefore = await provider.getBalance(
                    richAddress,
                );

                const txData = ethTransfer(richAddress, amount);
                const tx = await prepareMockTx(
                    provider,
                    account,
                    txData,
                    await newR1Validator.getAddress(),
                );
                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                const richBalanceAfter = await provider.getBalance(richAddress);
                expect(richBalanceAfter).to.be.equal(
                    richBalanceBefore + amount,
                );
            });

            it('should remove the new r1 validator', async () => {
                const validatorAddress = await newR1Validator.getAddress();
                expect(await account.r1IsValidator(validatorAddress)).to.be
                    .true;

                await removeR1Validator(
                    provider,
                    account,
                    teeValidator,
                    newR1Validator,
                    keyPair,
                );

                expect(await account.r1IsValidator(validatorAddress)).to.be
                    .false;

                const expectedValidators = [await teeValidator.getAddress()];

                expect(await account.r1ListValidators()).to.deep.eq(
                    expectedValidators,
                );
            });
        });

        describe('Non-full tests with k1 validator type, adding-removing, not-validating', () => {
            let newK1Validator: Contract;

            it('should add a new k1 validator', async () => {
                newK1Validator = await deployer.validator(VALIDATORS.EOA);
                const validatorAddress = await newK1Validator.getAddress();

                expect(await account.k1IsValidator(newK1Validator)).to.be.false;

                await addK1Validator(
                    provider,
                    account,
                    teeValidator,
                    newK1Validator,
                    keyPair,
                );

                expect(await account.k1IsValidator(newK1Validator)).to.be.true;

                const expectedValidators = [validatorAddress];

                expect(await account.k1ListValidators()).to.deep.eq(
                    expectedValidators,
                );
            });

            it('should remove a k1 validator', async () => {
                const validatorAddress = await newK1Validator.getAddress();
                expect(await account.k1IsValidator(validatorAddress)).to.be
                    .true;

                await removeK1Validator(
                    provider,
                    account,
                    teeValidator,
                    newK1Validator,
                    keyPair,
                );

                expect(await account.r1IsValidator(validatorAddress)).to.be
                    .false;

                expect(await account.k1ListValidators()).to.deep.eq([]);
            });
        });

        describe('Additional tests for r1 and k1 validators', () => {
            it('should revert adding new r1 and k1 validator with unauthorized msg.sender', async () => {
                const newR1Validator = await deployer.validator(
                    VALIDATORS.MOCK,
                );
                const r1ValidatorAddress = await newR1Validator.getAddress();

                const newK1Validator = await deployer.validator(VALIDATORS.EOA);
                const k1ValidatorAddress = await newK1Validator.getAddress();

                await expect(
                    account.r1AddValidator(r1ValidatorAddress),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );

                await expect(
                    account.k1AddValidator(k1ValidatorAddress),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('should revert adding new r1 and k1 validator with unauthorized msg.sender', async () => {
                const newR1Validator = await deployer.validator(
                    VALIDATORS.MOCK,
                );
                const r1ValidatorAddress = await newR1Validator.getAddress();

                await addR1Validator(
                    provider,
                    account,
                    teeValidator,
                    newR1Validator,
                    keyPair,
                );
                expect(await account.r1IsValidator(r1ValidatorAddress)).to.be
                    .true;

                await expect(
                    account.r1RemoveValidator(
                        await newR1Validator.getAddress(),
                    ),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );

                const newK1Validator = await deployer.validator(VALIDATORS.EOA);
                const k1ValidatorAddress = await newK1Validator.getAddress();

                await addK1Validator(
                    provider,
                    account,
                    teeValidator,
                    newK1Validator,
                    keyPair,
                );
                expect(await account.k1IsValidator(k1ValidatorAddress)).to.be
                    .true;

                await expect(
                    account.k1RemoveValidator(
                        await newK1Validator.getAddress(),
                    ),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );

                await removeR1Validator(
                    provider,
                    account,
                    teeValidator,
                    newR1Validator,
                    keyPair,
                );
                await removeK1Validator(
                    provider,
                    account,
                    teeValidator,
                    newK1Validator,
                    keyPair,
                );
            });

            it('should revert adding new r1 and k1 validator with WRONG interface', async () => {
                const wrongR1Validator = await deployer.validator(
                    VALIDATORS.EOA,
                );

                const wrongK1Validator = await deployer.validator(
                    VALIDATORS.MOCK,
                );

                try {
                    await addR1Validator(
                        provider,
                        account,
                        teeValidator,
                        wrongR1Validator,
                        keyPair,
                    );
                    assert(false, 'Should revert');
                } catch (err) {}

                try {
                    await addK1Validator(
                        provider,
                        account,
                        teeValidator,
                        wrongK1Validator,
                        keyPair,
                    );
                    assert(false, 'Should revert');
                } catch (err) {}
            });

            it('should revert adding new r1 and k1 validator with NO interface', async () => {
                const noInterfaceValidator = Wallet.createRandom();
                const validatorAddress =
                    await noInterfaceValidator.getAddress();

                try {
                    await addR1Validator(
                        provider,
                        account,
                        teeValidator,
                        new Contract(validatorAddress, []),
                        keyPair,
                    );
                    assert(false, 'Should revert');
                } catch (err) {}

                try {
                    await addK1Validator(
                        provider,
                        account,
                        teeValidator,
                        new Contract(validatorAddress, []),
                        keyPair,
                    );
                    assert(false, 'Should revert');
                } catch (err) {}
            });

            it('should revert removing the last r1 validator', async () => {
                const expectedValidators = [await teeValidator.getAddress()];

                expect(await account.r1ListValidators()).to.deep.eq(
                    expectedValidators,
                );

                try {
                    await removeR1Validator(
                        provider,
                        account,
                        teeValidator,
                        teeValidator,
                        keyPair,
                    );
                    assert(false, 'Should revert');
                } catch (err) {}
            });
        });
    });
});
