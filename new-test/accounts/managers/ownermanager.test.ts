/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { expect } from 'chai';
import type { ec } from 'elliptic';
import { parseEther } from 'ethers';
import * as hre from 'hardhat';
import type { Contract, Wallet } from 'zksync-ethers';
import { Provider, utils } from 'zksync-ethers';

import { LOCAL_RICH_WALLETS, getWallet } from '../../../deploy/utils';
import { ClaveDeployer } from '../../utils/deployer';
import { fixture } from '../../utils/fixture';
import { VALIDATORS } from '../../utils/names';
import { encodePublicKey, genKey } from '../../utils/p256';
import { prepareTeeTx } from '../../utils/transactions';

describe('Clave Contracts - Manager tests', () => {
    let deployer: ClaveDeployer;
    let provider: Provider;
    let richWallet: Wallet;
    let validator: Contract;
    let account: Contract;
    let keyPair: ec.KeyPair;

    let erc20: Contract;

    before(async () => {
        richWallet = getWallet(hre, LOCAL_RICH_WALLETS[0].privateKey);
        deployer = new ClaveDeployer(hre, richWallet);
        provider = new Provider(hre.network.config.url, undefined, {
            cacheTimeout: -1,
        });

        [, , , , validator, account, keyPair] = await fixture(
            deployer,
            // VALIDATORS.TEE, // FIXME: non-Mock validators not working
        );

        const accountAddress = await account.getAddress();

        await deployer.fund(10000, accountAddress);

        erc20 = await deployer.deployCustomContract('MockStable', []);
        await erc20.mint(accountAddress, parseEther('100000'));
    });

    describe('Owner Manager', () => {
        it('should check existing key', async () => {
            const newPublicKey = encodePublicKey(keyPair);
            expect(await account.r1IsOwner(newPublicKey)).to.be.true;
        });

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
                await validator.getAddress(),
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

        it('should remove an r1 key', async () => {
            expect(await account.r1IsOwner(newPublicKey)).to.be.true;

            const removeOwnerTxData =
                await account.r1RemoveOwner.populateTransaction(newPublicKey);

            const tx = await prepareTeeTx(
                provider,
                account,
                removeOwnerTxData,
                await validator.getAddress(),
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
    });
});
