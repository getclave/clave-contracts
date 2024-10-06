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
import { encodePublicKey, genKey } from '../../utils/p256';
import {
    executeRecovery,
    startCloudRecovery,
    stopRecovery,
    updateCloudGuardian,
} from '../../utils/recovery/recovery';

describe('Clave Contracts - Manager tests', () => {
    let deployer: ClaveDeployer;
    let provider: Provider;
    let richWallet: Wallet;
    let teeValidator: Contract;
    let account: Contract;
    let keyPair: ec.KeyPair;

    let cloudRecoveryModule: Contract;

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

        cloudRecoveryModule = await deployer.deployCustomContract(
            'CloudRecoveryModule',
            ['TEST', '0', 0],
        );
    });

    describe('Module Tests - Cloud Recovery Module', () => {
        let cloudGuardian: Wallet;
        let newKeyPair: ec.KeyPair;

        describe('Adding & Initializing module', () => {
            before(async () => {
                cloudGuardian = new Wallet(
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
                        await cloudRecoveryModule.getAddress(),
                    ),
                ).to.be.false;

                const initData = AbiCoder.defaultAbiCoder().encode(
                    ['address'],
                    [await cloudGuardian.getAddress()],
                );
                await addModule(
                    provider,
                    account,
                    teeValidator,
                    cloudRecoveryModule,
                    initData,
                    keyPair,
                );
                expect(
                    await account.isModule(
                        await cloudRecoveryModule.getAddress(),
                    ),
                ).to.be.true;

                const expectedModules = [
                    await cloudRecoveryModule.getAddress(),
                ];
                expect(await account.listModules()).to.deep.eq(expectedModules);
            });

            it('should init the module successfully', async () => {
                const status = await cloudRecoveryModule.isInited(
                    await account.getAddress(),
                );
                expect(status).to.eq(true);
            });

            it('should assign the guardian correctly', async () => {
                const guardian = await cloudRecoveryModule.getGuardian(
                    await account.getAddress(),
                );
                expect(guardian).to.eq(await cloudGuardian.getAddress());
            });
        });

        describe('Recovery process', () => {
            it('should start recovery process', async () => {
                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.false;

                expect(await account.r1ListOwners()).to.deep.eq([
                    encodePublicKey(keyPair),
                ]);

                await startCloudRecovery(
                    cloudGuardian,
                    account,
                    cloudRecoveryModule,
                    encodePublicKey(newKeyPair),
                );

                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.true;
            });

            it('should execute recovery process', async () => {
                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.true;

                expect(await account.r1ListOwners()).to.deep.eq([
                    encodePublicKey(keyPair),
                ]);

                await executeRecovery(account, cloudRecoveryModule);

                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.false;

                expect(await account.r1ListOwners()).to.deep.eq([
                    encodePublicKey(newKeyPair),
                ]);
            });
        });

        describe('Alternative recovery process scenarios', () => {
            let newNewKeyPair: ec.KeyPair;

            before(async () => {
                newNewKeyPair = genKey();
            });

            it('shoud revert changing the guardian if recovery is in progress', async () => {
                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.false;

                await startCloudRecovery(
                    cloudGuardian,
                    account,
                    cloudRecoveryModule,
                    encodePublicKey(newNewKeyPair),
                );

                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.true;

                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.true;
                const guardian = await cloudRecoveryModule.getGuardian(
                    await account.getAddress(),
                );
                expect(guardian).to.eq(await cloudGuardian.getAddress());

                const newGuardianAddress = new Wallet(
                    Wallet.createRandom().privateKey,
                    provider,
                );

                try {
                    await updateCloudGuardian(
                        provider,
                        account,
                        cloudRecoveryModule,
                        teeValidator,
                        await newGuardianAddress.getAddress(),
                        keyPair,
                    );
                    assert(false, 'Should revert');
                } catch (err) {}

                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.true;
                const guardianLater = await cloudRecoveryModule.getGuardian(
                    await account.getAddress(),
                );
                expect(guardian).to.eq(guardianLater);
            });

            it('should stop the recovery process', async () => {
                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.true;

                await stopRecovery(
                    provider,
                    account,
                    cloudRecoveryModule,
                    teeValidator,
                    newKeyPair,
                );

                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.false;
            });
        });
    });
});
