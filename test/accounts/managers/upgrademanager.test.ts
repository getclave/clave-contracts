/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { assert, expect } from 'chai';
import type { ec } from 'elliptic';
import * as hre from 'hardhat';
import type { Contract, Wallet } from 'zksync-ethers';
import { Provider } from 'zksync-ethers';

import { LOCAL_RICH_WALLETS, getWallet } from '../../../deploy/utils';
import { ClaveDeployer } from '../../utils/deployer';
import { fixture } from '../../utils/fixture';
import { upgradeTx } from '../../utils/managers/upgrademanager';
import { VALIDATORS } from '../../utils/names';

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

    describe('Upgrade Manager', () => {
        let mockImplementation: Contract;

        before(async () => {
            mockImplementation = await deployer.deployCustomContract(
                'MockImplementation',
                [],
            );
        });

        it('should revert to a new implementation with unauthorized msg.sender', async () => {
            await expect(
                account.upgradeTo(await mockImplementation.getAddress()),
            ).to.be.revertedWithCustomError(account, 'NOT_FROM_SELF');
        });

        it('should upgrade to a new implementation', async () => {
            expect(await account.implementation()).not.to.be.eq(
                await mockImplementation.getAddress(),
            );

            await upgradeTx(
                provider,
                account,
                teeValidator,
                mockImplementation,
                keyPair,
            );

            expect(await account.implementation()).to.eq(
                await mockImplementation.getAddress(),
            );
        });

        it('should revert upgrading to the same implementation', async () => {
            expect(await account.implementation()).to.be.eq(
                await mockImplementation.getAddress(),
            );

            try {
                await upgradeTx(
                    provider,
                    account,
                    teeValidator,
                    mockImplementation,
                    keyPair,
                );
                assert(false, 'Should revert');
            } catch (err) {}
        });
    });
});
