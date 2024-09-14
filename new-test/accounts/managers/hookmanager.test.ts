/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { expect } from 'chai';
import type { ec } from 'elliptic';
import * as hre from 'hardhat';
import type { Contract, Wallet } from 'zksync-ethers';
import { Provider } from 'zksync-ethers';

import { LOCAL_RICH_WALLETS, getWallet } from '../../../deploy/utils';
import { ClaveDeployer } from '../../utils/deployer';
import { fixture } from '../../utils/fixture';
import { addHook, removeHook } from '../../utils/managers/hookmanager';
import { HOOKS, VALIDATORS } from '../../utils/names';

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

    describe('Hook Manager', () => {
        it('should check existing modules', async () => {
            expect(await account.listHooks(HOOKS.VALIDATION)).to.deep.eq([]);
            expect(await account.listHooks(HOOKS.EXECUTION)).to.deep.eq([]);
        });

        describe('Validation hooks', async () => {
            let validationHook: Contract;

            it('should add a validation hook', async () => {
                validationHook = await deployer.deployCustomContract(
                    'MockValidationHook',
                    [],
                );
                expect(await account.isHook(await validationHook.getAddress()))
                    .to.be.false;

                await addHook(
                    provider,
                    account,
                    teeValidator,
                    validationHook,
                    HOOKS.VALIDATION,
                    keyPair,
                );

                expect(await account.isHook(await validationHook.getAddress()))
                    .to.be.true;

                const expectedHooks = [await validationHook.getAddress()];
                expect(await account.listHooks(HOOKS.VALIDATION)).to.deep.eq(
                    expectedHooks,
                );
            });

            it('should remove a validation hook', async () => {
                expect(await account.isHook(await validationHook.getAddress()))
                    .to.be.true;

                await removeHook(
                    provider,
                    account,
                    teeValidator,
                    validationHook,
                    HOOKS.VALIDATION,
                    keyPair,
                );
                expect(await account.isHook(await validationHook.getAddress()))
                    .to.be.false;

                expect(await account.listHooks(HOOKS.VALIDATION)).to.deep.eq(
                    [],
                );
            });
        });

        describe('Execution hooks', async () => {
            let executionHook: Contract;

            it('should add a execution hook', async () => {
                executionHook = await deployer.deployCustomContract(
                    'MockExecutionHook',
                    [],
                );
                expect(await account.isHook(await executionHook.getAddress()))
                    .to.be.false;

                await addHook(
                    provider,
                    account,
                    teeValidator,
                    executionHook,
                    HOOKS.EXECUTION,
                    keyPair,
                );

                expect(await account.isHook(await executionHook.getAddress()))
                    .to.be.true;

                const expectedHooks = [await executionHook.getAddress()];
                expect(await account.listHooks(HOOKS.EXECUTION)).to.deep.eq(
                    expectedHooks,
                );
            });

            it('should remove a execution hook', async () => {
                expect(await account.isHook(await executionHook.getAddress()))
                    .to.be.true;

                await removeHook(
                    provider,
                    account,
                    teeValidator,
                    executionHook,
                    HOOKS.EXECUTION,
                    keyPair,
                );
                expect(await account.isHook(await executionHook.getAddress()))
                    .to.be.false;

                expect(await account.listHooks(HOOKS.EXECUTION)).to.deep.eq([]);
            });
        });
    });
});
