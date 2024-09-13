/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { expect } from 'chai';
import type { ec } from 'elliptic';
import { parseEther } from 'ethers';
import * as hre from 'hardhat';
import type { Contract } from 'zksync-ethers';
import { Provider, Wallet, utils } from 'zksync-ethers';

import { LOCAL_RICH_WALLETS, getWallet } from '../../../deploy/utils';
import { ClaveDeployer } from '../../utils/deployer';
import { fixture } from '../../utils/fixture';
import { VALIDATORS } from '../../utils/names';
import { encodePublicKey, genKey } from '../../utils/p256';
import { ethTransfer, prepareTeeTx } from '../../utils/transactions';

describe('Clave Contracts - Manager tests', () => {
    let deployer: ClaveDeployer;
    let provider: Provider;
    let richWallet: Wallet;
    let mockValidator: Contract;
    let account: Contract;
    let keyPair: ec.KeyPair;

    before(async () => {
        richWallet = getWallet(hre, LOCAL_RICH_WALLETS[0].privateKey);
        deployer = new ClaveDeployer(hre, richWallet);
        provider = new Provider(hre.network.config.url, undefined, {
            cacheTimeout: -1,
        });

        [, , , , mockValidator, account, keyPair] = await fixture(
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

                const addOwnerTx = await account.r1AddOwner.populateTransaction(
                    newPublicKey,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    await mockValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

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
                    await mockValidator.getAddress(),
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

                const removeOwnerTxData =
                    await account.r1RemoveOwner.populateTransaction(
                        newPublicKey,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    removeOwnerTxData,
                    await mockValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

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
                    await mockValidator.getAddress(),
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

                const addOwnerTx = await account.k1AddOwner.populateTransaction(
                    newK1Address,
                );
                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    await mockValidator.getAddress(),
                    keyPair,
                );
                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsOwner(newK1Address)).to.be.true;

                const expectedOwners = [newK1Address];
                expect(await account.k1ListOwners()).to.deep.eq(expectedOwners);
            });

            it('should remove the new k1 key', async () => {
                expect(await account.k1IsOwner(newK1Address)).to.be.true;

                const removeOwnerTx =
                    await account.k1RemoveOwner.populateTransaction(
                        newK1Address,
                    );
                const tx = await prepareTeeTx(
                    provider,
                    account,
                    removeOwnerTx,
                    await mockValidator.getAddress(),
                    keyPair,
                );
                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsOwner(newK1Address)).to.be.false;
                const expectedOwners: Array<string> = [];
                expect(await account.k1ListOwners()).to.deep.eq(expectedOwners);
            });
        });
    });
});
