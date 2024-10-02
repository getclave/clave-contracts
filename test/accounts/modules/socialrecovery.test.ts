/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { assert, expect } from 'chai';
import type { ec } from 'elliptic';
import { AbiCoder } from 'ethers';
import * as hre from 'hardhat';
import type { Contract } from 'zksync-ethers';
import { Provider, Wallet } from 'zksync-ethers';

import { LOCAL_RICH_WALLETS, getWallet } from '../../../deploy/utils';
import { ClaveDeployer } from '../../utils/deployer';
import { fixture } from '../../utils/fixture';
import { addModule } from '../../utils/managers/modulemanager';
import { VALIDATORS } from '../../utils/names';
import { genKey } from '../../utils/p256';

describe('Clave Contracts - Manager tests', () => {
    let deployer: ClaveDeployer;
    let provider: Provider;
    let richWallet: Wallet;
    let teeValidator: Contract;
    let account: Contract;
    let keyPair: ec.KeyPair;

    let socialRecoveryModule: Contract;

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

        socialRecoveryModule = await deployer.deployCustomContract(
            'SocialRecoveryModule',
            ['TEST', '0', 0, 1],
        );
    });

    describe('Module Tests - Social Recovery Module', () => {
        let socialGuardian: Wallet;
        let newKeyPair: ec.KeyPair;

        describe('Adding & Initializing module', () => {
            before(async () => {
                socialGuardian = new Wallet(
                    Wallet.createRandom().privateKey,
                    provider,
                );

                newKeyPair = genKey();
            });

            it('should check existing modules', async () => {
                expect(await account.listModules()).to.deep.eq([]);
            });

            it('should add a new module', async () => {
                expect(
                    await account.isModule(
                        await socialRecoveryModule.getAddress(),
                    ),
                ).to.be.false;

                const initData = AbiCoder.defaultAbiCoder().encode(
                    ['uint128', 'uin128', 'address[]'],
                    [0, 1, []],
                );
                await addModule(
                    provider,
                    account,
                    teeValidator,
                    socialRecoveryModule,
                    initData,
                    keyPair,
                );
                expect(
                    await account.isModule(
                        await socialRecoveryModule.getAddress(),
                    ),
                ).to.be.true;

                const expectedModules = [
                    await socialRecoveryModule.getAddress(),
                ];
                expect(await account.listModules()).to.deep.eq(expectedModules);
            });

            it('should init the module successfully', async () => {
                const status = await socialRecoveryModule.isInited(
                    await account.getAddress(),
                );
                expect(status).to.eq(true);
            });

            it('should assign the guardian correctly', async () => {
                const guardians = await socialRecoveryModule.getGuardians(
                    await account.getAddress(),
                );
                expect(guardians).to.deep.eq([
                    await socialGuardian.getAddress(),
                ]);
            });
        });
    });
});
