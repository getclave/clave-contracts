/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { assert, expect } from 'chai';
import type { ec } from 'elliptic';
import type { BytesLike } from 'ethers';
import { ZeroAddress, parseEther } from 'ethers';
import * as hre from 'hardhat';
import type { Contract } from 'zksync-ethers';
import { Provider, Wallet, utils } from 'zksync-ethers';

import { LOCAL_RICH_WALLETS, getWallet } from '../../../deploy/utils';
import { ClaveDeployer } from '../../utils/deployer';
import { fixture } from '../../utils/fixture';
import {
    addK1Key,
    addR1Key,
    removeK1Key,
    removeR1Key,
    resetOwners,
} from '../../utils/managers/ownermanager';
import { VALIDATORS } from '../../utils/names';
import { encodePublicKey, genKey } from '../../utils/p256';
import { ethTransfer, prepareTeeTx } from '../../utils/transactions';

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

    describe('Owner Manager', () => {
        it('should check existing key', async () => {
            const newPublicKey = encodePublicKey(keyPair);
            expect(await account.r1IsOwner(newPublicKey)).to.be.true;
        });

        describe('Full tests with a new r1 key, adding-removing-validating', () => {
            let newKeyPair: ec.KeyPair;
            let newPublicKey: string;

            it('should create a new r1 key and add as a new owner', async () => {
                newKeyPair = genKey();
                newPublicKey = encodePublicKey(newKeyPair);

                expect(await account.r1IsOwner(newPublicKey)).to.be.false;

                await addR1Key(
                    provider,
                    account,
                    teeValidator,
                    newPublicKey,
                    keyPair,
                );

                expect(await account.r1IsOwner(newPublicKey)).to.be.true;

                const expectedOwners = [newPublicKey, encodePublicKey(keyPair)];
                expect(await account.r1ListOwners()).to.deep.eq(expectedOwners);
            });

            it('should send a tx with the new key', async () => {
                const amount = parseEther('1');
                const richAddress = await richWallet.getAddress();
                const richBalanceBefore = await provider.getBalance(
                    richAddress,
                );

                const txData = ethTransfer(richAddress, amount);
                const tx = await prepareTeeTx(
                    provider,
                    account,
                    txData,
                    await teeValidator.getAddress(),
                    newKeyPair,
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

            it('should remove an r1 key', async () => {
                expect(await account.r1IsOwner(newPublicKey)).to.be.true;

                await removeR1Key(
                    provider,
                    account,
                    teeValidator,
                    newPublicKey,
                    keyPair,
                );

                expect(await account.r1IsOwner(newPublicKey)).to.be.false;

                const expectedOwners = [encodePublicKey(keyPair)];

                expect(await account.r1ListOwners()).to.deep.eq(expectedOwners);
            });

            it('should not send any tx with the removed key', async () => {
                const amount = parseEther('1');
                const richAddress = await richWallet.getAddress();
                const richBalanceBefore = await provider.getBalance(
                    richAddress,
                );

                expect(richBalanceBefore).to.be.greaterThan(amount);

                const txData = ethTransfer(richAddress, amount);
                const tx = await prepareTeeTx(
                    provider,
                    account,
                    txData,
                    await teeValidator.getAddress(),
                    newKeyPair,
                );
                await expect(
                    provider.broadcastTransaction(utils.serializeEip712(tx)),
                ).to.be.reverted;
            });
        });

        describe('Non-full tests with a new k1 key, adding-removing, not validating', () => {
            let newK1Address: string;
            it('should add a new k1 key', async () => {
                newK1Address = await Wallet.createRandom().getAddress();

                expect(await account.k1IsOwner(newK1Address)).to.be.false;

                await addK1Key(
                    provider,
                    account,
                    teeValidator,
                    newK1Address,
                    keyPair,
                );

                expect(await account.k1IsOwner(newK1Address)).to.be.true;

                const expectedOwners = [newK1Address];
                expect(await account.k1ListOwners()).to.deep.eq(expectedOwners);
            });

            it('should remove the new k1 key', async () => {
                expect(await account.k1IsOwner(newK1Address)).to.be.true;

                await removeK1Key(
                    provider,
                    account,
                    teeValidator,
                    newK1Address,
                    keyPair,
                );

                expect(await account.k1IsOwner(newK1Address)).to.be.false;
                const expectedOwners: Array<string> = [];
                expect(await account.k1ListOwners()).to.deep.eq(expectedOwners);
            });
        });

        describe('Additinal tests for r1 and k1 keys', () => {
            let replacedKeyPair: ec.KeyPair;

            it('Should reset owners', async () => {
                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);
                await addR1Key(
                    provider,
                    account,
                    teeValidator,
                    newPublicKey,
                    keyPair,
                );

                const newK1Address = await Wallet.createRandom().getAddress();
                await addK1Key(
                    provider,
                    account,
                    teeValidator,
                    newK1Address,
                    keyPair,
                );

                const expectedR1Owners = [
                    newPublicKey,
                    encodePublicKey(keyPair),
                ];
                expect(await account.r1ListOwners()).to.deep.eq(
                    expectedR1Owners,
                );

                const expectedK1Owners = [newK1Address];
                expect(await account.k1ListOwners()).to.deep.eq(
                    expectedK1Owners,
                );

                await resetOwners(
                    provider,
                    account,
                    teeValidator,
                    newPublicKey,
                    keyPair,
                );
                replacedKeyPair = newKeyPair;

                const expectedNewR1Owners = [encodePublicKey(replacedKeyPair)];
                const expectedNewK1Owners: Array<BytesLike> = [];

                expect(await account.r1ListOwners()).to.deep.eq(
                    expectedNewR1Owners,
                );
                expect(await account.k1ListOwners()).to.deep.eq(
                    expectedNewK1Owners,
                );
            });

            it('Should revert the r1 owner with invalid length', async () => {
                let invalidLength = Math.ceil(Math.random() * 200) * 2;
                invalidLength = invalidLength === 128 ? 130 : invalidLength;

                const invalidPubkey = '0x' + 'C'.repeat(invalidLength);

                try {
                    await addR1Key(
                        provider,
                        account,
                        teeValidator,
                        invalidPubkey,
                        replacedKeyPair,
                    );
                    assert(false, 'Should revert');
                } catch (err) {}
            });

            it('Should revert adding new r1 or k1 owner with unauthorized msg.sender', async function () {
                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);

                await expect(
                    account.r1AddOwner(newPublicKey),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account.k1AddOwner(await randomWallet.getAddress()),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Should revert removing r1 or k1 owners and resetting owners with unauthorized msg.sender, then should reset owners to the initial', async function () {
                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);

                await addR1Key(
                    provider,
                    account,
                    teeValidator,
                    newPublicKey,
                    replacedKeyPair,
                );

                expect(await account.r1IsOwner(newPublicKey)).to.be.true;

                await expect(
                    account.r1RemoveOwner(newPublicKey),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );

                const newAddress = await Wallet.createRandom().getAddress();

                await addK1Key(
                    provider,
                    account,
                    teeValidator,
                    newAddress,
                    replacedKeyPair,
                );

                expect(await account.k1IsOwner(newAddress)).to.be.true;

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account.k1RemoveOwner(await randomWallet.getAddress()),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );

                await resetOwners(
                    provider,
                    account,
                    teeValidator,
                    encodePublicKey(replacedKeyPair),
                    replacedKeyPair,
                );

                const expectedNewR1Owners = [encodePublicKey(replacedKeyPair)];
                const expectedNewK1Owners: Array<BytesLike> = [];

                expect(await account.r1ListOwners()).to.deep.eq(
                    expectedNewR1Owners,
                );
                expect(await account.k1ListOwners()).to.deep.eq(
                    expectedNewK1Owners,
                );

                await expect(
                    account.resetOwners(newPublicKey),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Should revert adding zero address as k1 owner', async function () {
                try {
                    await addK1Key(
                        provider,
                        account,
                        teeValidator,
                        ZeroAddress,
                        replacedKeyPair,
                    );
                    assert(false, 'Should revert');
                } catch (err) {}
            });

            it('Should revert removing the last r1 owner', async function () {
                try {
                    await removeR1Key(
                        provider,
                        account,
                        teeValidator,
                        encodePublicKey(replacedKeyPair),
                        replacedKeyPair,
                    );
                    assert(false, 'Should revert');
                } catch (err) {}
            });

            it('Should revert resetting owners while new r1 owner has invalid length', async function () {
                let invalidLength = Math.ceil(Math.random() * 200) * 2;
                invalidLength = invalidLength === 128 ? 130 : invalidLength;

                const invalidPubkey = '0x' + 'C'.repeat(invalidLength);

                try {
                    await removeR1Key(
                        provider,
                        account,
                        teeValidator,
                        invalidPubkey,
                        replacedKeyPair,
                    );
                    assert(false, 'Should revert');
                } catch (err) {}
            });
        });
    });
});
