/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { expect } from 'chai';
import type { ec } from 'elliptic';
import type { BytesLike } from 'ethers';
import { parseEther } from 'ethers';
import * as hre from 'hardhat';
import type { Contract, Wallet } from 'zksync-ethers';
import { Provider } from 'zksync-ethers';

import { LOCAL_RICH_WALLETS, getWallet } from '../../deploy/utils';
import { ClaveDeployer } from '../utils/deployer';
import { fixture } from '../utils/fixture';
import { encodePublicKey } from '../utils/p256';

describe('Clave Contracts - Deployer class tests', () => {
    let deployer: ClaveDeployer;
    let provider: Provider;
    let richWallet: Wallet;
    let batchCaller: Contract;
    let registry: Contract;
    let implementation: Contract;
    let factory: Contract;
    let mockValidator: Contract;
    let account: Contract;
    let keyPair: ec.KeyPair;

    before(async () => {
        richWallet = getWallet(hre, LOCAL_RICH_WALLETS[0].privateKey);
        deployer = new ClaveDeployer(hre, richWallet);
        provider = new Provider(hre.network.config.url, undefined, {
            cacheTimeout: -1,
        });

        [
            batchCaller,
            registry,
            implementation,
            factory,
            mockValidator,
            account,
            keyPair,
        ] = await fixture(deployer);

        await deployer.fund(100, await account.getAddress());
    });

    describe('Contracts', () => {
        it('should deploy the contracts', async () => {
            expect(await batchCaller.getAddress()).not.to.be.undefined;
            expect(await registry.getAddress()).not.to.be.undefined;
            expect(await implementation.getAddress()).not.to.be.undefined;
            expect(await factory.getAddress()).not.to.be.undefined;
            expect(await mockValidator.getAddress()).not.to.be.undefined;
            expect(await account.getAddress()).not.to.be.undefined;
        });
    });

    describe('States', () => {
        it('should fund the account', async () => {
            const balance = await provider.getBalance(
                await account.getAddress(),
            );
            expect(balance).to.eq(parseEther('100'));
        });

        it('account keeps correct states', async () => {
            const validatorAddress = await mockValidator.getAddress();
            const implementationAddress = await implementation.getAddress();

            const expectedR1Validators = [validatorAddress];
            const expectedK1Validators: Array<BytesLike> = [];
            const expectedR1Owners = [encodePublicKey(keyPair)];
            const expectedK1Owners: Array<BytesLike> = [];
            const expectedModules: Array<BytesLike> = [];
            const expectedHooks: Array<BytesLike> = [];
            const expectedImplementation = implementationAddress;

            expect(await account.r1ListValidators()).to.deep.eq(
                expectedR1Validators,
            );
            expect(await account.k1ListValidators()).to.deep.eq(
                expectedK1Validators,
            );
            expect(await account.r1ListOwners()).to.deep.eq(expectedR1Owners);
            expect(await account.k1ListOwners()).to.deep.eq(expectedK1Owners);
            expect(await account.listModules()).to.deep.eq(expectedModules);
            expect(await account.listHooks(false)).to.deep.eq(expectedHooks);
            expect(await account.listHooks(true)).to.deep.eq(expectedHooks);
            expect(await account.implementation()).to.eq(
                expectedImplementation,
            );
        });

        it('registry is deployed and states are expected', async function () {
            const accountAddress = await account.getAddress();
            const factoryAddress = await factory.getAddress();

            expect(await registry.isClave(accountAddress)).to.be.true;
            expect(await registry.isClave(factoryAddress)).not.to.be.true;
        });
    });
});
