/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { expect } from 'chai';
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
import { startRecovery } from '../../utils/recovery/recovery';

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

    describe('Module Tests - Cloud Recovery Module', () => {
        let cloudRecoveryModule: Contract;
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
                cloudRecoveryModule = await deployer.deployCustomContract(
                    'CloudRecoveryModule',
                    ['TEST', '0', 0],
                );
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

            it('should start recovery process', async () => {
                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.false;

                await startRecovery(
                    cloudGuardian,
                    account,
                    cloudRecoveryModule,
                    teeValidator,
                    encodePublicKey(newKeyPair),
                );

                expect(
                    await cloudRecoveryModule.isRecovering(
                        await account.getAddress(),
                    ),
                ).to.be.true;
            });
        });
    });
});
