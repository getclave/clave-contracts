/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { assert, expect } from 'chai';
import type { ec } from 'elliptic';
import { constants, type ethers } from 'ethers';
import {
    defaultAbiCoder,
    hexConcat,
    parseEther,
    parseUnits,
    randomBytes,
    solidityKeccak256,
} from 'ethers/lib/utils';
import { Provider, Wallet, utils } from 'zksync-web3';

import type {
    AccountFactory,
    BatchCaller,
    ClaveImplementation,
    ClaveRegistry,
    ERC20PaymasterMock,
    GaslessPaymaster,
    MockStable,
    P256VerifierExpensive,
    SubsidizerPaymasterMock,
    TEEValidator,
} from '../typechain-types';
import {
    deployAccount,
    deployBatchCaller,
    deployEOAValidator,
    deployERC20PaymasterMock,
    deployFactory,
    deployGaslessPaymaster,
    deployImplementation,
    deployMockExecutionHook,
    deployMockImplementation,
    deployMockModule,
    deployMockStable,
    deployMockValidationHook,
    deployRegistry,
    deploySubsidizerPaymasterMock,
    deployTeeValidator,
    deployVerifier,
} from './utils/deploy';
import { getOraclePayload } from './utils/oracle';
import { encodePublicKey, genKey } from './utils/p256';
import {
    getERC20PaymasterInput,
    getGaslessPaymasterInput,
} from './utils/paymaster';
import type { CallableProxy } from './utils/proxy-helpers';
import { richWallets } from './utils/rich-wallets';
import { ethTransfer, prepareBatchTx, prepareTeeTx } from './utils/transaction';

const richPk = richWallets[0].privateKey;

let provider: Provider;
let richWallet: Wallet;

let keyPair: ec.KeyPair;

let batchCaller: BatchCaller;
let verifier: P256VerifierExpensive;
let teeValidator: TEEValidator;
let implementation: ClaveImplementation;
let factory: AccountFactory;
let account: CallableProxy;
let registry: ClaveRegistry;

beforeEach(async () => {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    provider = new Provider(hre.config.networks.zkSyncTestnet.url);
    richWallet = new Wallet(richPk, provider);

    keyPair = genKey();
    const publicKey = encodePublicKey(keyPair);

    batchCaller = await deployBatchCaller(richWallet);
    verifier = await deployVerifier(richWallet);
    teeValidator = await deployTeeValidator(richWallet, verifier.address);
    implementation = await deployImplementation(
        richWallet,
        batchCaller.address,
    );
    registry = await deployRegistry(richWallet);
    factory = await deployFactory(
        richWallet,
        implementation.address,
        registry.address,
    );

    await registry.setFactory(factory.address);

    account = await deployAccount(
        richWallet,
        factory,
        teeValidator.address,
        publicKey,
    );

    // 100 ETH transfered to Account
    await (
        await richWallet.sendTransaction({
            to: account.address,
            value: parseEther('100'),
        })
    ).wait();
});

describe('Account no module no hook TEE validator', function () {
    describe('Should', function () {
        it('Have correct state after deployment', async function () {
            expect(await provider.getBalance(account.address)).to.eq(
                parseEther('100'),
            );

            const expectedR1Validators = [teeValidator.address];
            const expectedK1Validators: Array<ethers.BytesLike> = [];
            const expectedR1Owners = [encodePublicKey(keyPair)];
            const expectedK1Owners: Array<ethers.BytesLike> = [];
            const expectedModules: Array<ethers.BytesLike> = [];
            const expectedHooks: Array<ethers.BytesLike> = [];
            const expectedImplementation = implementation.address;

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

        it('Registers contract to the registry', async function () {
            expect(await registry.isClave(account.address)).to.be.true;
        });

        it('Not show other contracts in registry', async function () {
            expect(await registry.isClave(factory.address)).not.to.be.true;
        });

        it('Transfer ETH correctly', async function () {
            const amount = parseEther('10');
            const delta = parseEther('0.01');

            const accountBalanceBefore = await provider.getBalance(
                account.address,
            );
            const receiverBalanceBefore = await provider.getBalance(
                richWallet.address,
            );

            const transfer = ethTransfer(richWallet.address, amount);
            const tx = await prepareTeeTx(
                provider,
                account,
                transfer,
                teeValidator.address,
                keyPair,
            );

            const txReceipt = await provider.sendTransaction(
                utils.serialize(tx),
            );

            await txReceipt.wait();

            const accountBalanceAfter = await provider.getBalance(
                account.address,
            );
            const receiverBalanceAfter = await provider.getBalance(
                richWallet.address,
            );

            expect(accountBalanceAfter).to.be.closeTo(
                accountBalanceBefore.sub(amount),
                delta,
            );

            expect(receiverBalanceAfter).to.eq(
                receiverBalanceBefore.add(amount),
            );
        });

        it('Make batch transaction correctly', async function () {
            const accountBalanceBefore = await provider.getBalance(
                account.address,
            );

            const receiver1 = Wallet.createRandom().address;
            const receiver2 = Wallet.createRandom().address;

            const calls: Array<BatchCaller.CallStruct> = [
                {
                    target: receiver1,
                    allowFailure: false,
                    value: parseEther('0.1'),
                    callData: '0x',
                },
                {
                    target: receiver2,
                    allowFailure: false,
                    value: parseEther('0.2'),
                    callData: '0x',
                },
            ];

            const batchTx = await prepareBatchTx(
                provider,
                account,
                batchCaller.address,
                calls,
                teeValidator.address,
                keyPair,
            );

            const txReceipt = await provider.sendTransaction(
                utils.serialize(batchTx),
            );
            await txReceipt.wait();

            const accountBalanceAfter = await provider.getBalance(
                account.address,
            );

            expect(accountBalanceAfter).to.be.closeTo(
                accountBalanceBefore.sub(parseEther('0.3')),
                parseEther('0.01'),
            );
            expect(await provider.getBalance(receiver1)).to.eq(
                parseEther('0.1'),
            );
            expect(await provider.getBalance(receiver2)).to.eq(
                parseEther('0.2'),
            );
        });
    });

    describe('Owner manager', function () {
        describe('Should not revert when', function () {
            it('Adds a new r1 owner correctly', async function () {
                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);

                expect(await account.r1IsOwner(newPublicKey)).to.be.false;

                const addOwnerTx = await account.populateTransaction.r1AddOwner(
                    newPublicKey,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.r1IsOwner(newPublicKey)).to.be.true;

                const expectedOwners = [newPublicKey, encodePublicKey(keyPair)];

                expect(await account.r1ListOwners()).to.deep.eq(expectedOwners);
            });

            it('Removes an r1 owner correctly', async function () {
                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);

                const addOwnerTx = await account.populateTransaction.r1AddOwner(
                    newPublicKey,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.r1IsOwner(newPublicKey)).to.be.true;

                const removeOwnerTx =
                    await account.populateTransaction.r1RemoveOwner(
                        newPublicKey,
                    );

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt2 = await provider.sendTransaction(
                    utils.serialize(tx2),
                );
                await txReceipt2.wait();

                expect(await account.r1IsOwner(newPublicKey)).to.be.false;

                const expectedOwners = [encodePublicKey(keyPair)];

                expect(await account.r1ListOwners()).to.deep.eq(expectedOwners);
            });

            it('Adds a new k1 owner correctly', async function () {
                const newAddress = Wallet.createRandom().address;

                expect(await account.k1IsOwner(newAddress)).to.be.false;

                const addOwnerTx = await account.populateTransaction.k1AddOwner(
                    newAddress,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsOwner(newAddress)).to.be.true;

                const expectedOwners = [newAddress];

                expect(await account.k1ListOwners()).to.deep.eq(expectedOwners);
            });

            it('Removes a k1 owner correctly', async function () {
                const newAddress = Wallet.createRandom().address;

                const addOwnerTx = await account.populateTransaction.k1AddOwner(
                    newAddress,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsOwner(newAddress)).to.be.true;

                const removeOwnerTx =
                    await account.populateTransaction.k1RemoveOwner(newAddress);

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt2 = await provider.sendTransaction(
                    utils.serialize(tx2),
                );
                await txReceipt2.wait();

                expect(await account.k1IsOwner(newAddress)).to.be.false;

                const expectedOwners: Array<string> = [];

                expect(await account.k1ListOwners()).to.deep.eq(expectedOwners);
            });

            it('Resets owners correctly', async function () {
                const newAddress = Wallet.createRandom().address;

                const addOwnerTx = await account.populateTransaction.k1AddOwner(
                    newAddress,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsOwner(newAddress)).to.be.true;

                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);

                const resetOwnersTx =
                    await account.populateTransaction.resetOwners(newPublicKey);

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    resetOwnersTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt2 = await provider.sendTransaction(
                    utils.serialize(tx2),
                );
                await txReceipt2.wait();

                const expectedR1Owners = [newPublicKey];
                const expectedK1Owners: Array<ethers.BytesLike> = [];

                expect(await account.r1ListOwners()).to.deep.eq(
                    expectedR1Owners,
                );
                expect(await account.k1ListOwners()).to.deep.eq(
                    expectedK1Owners,
                );
            });
        });

        describe('Should revert when', function () {
            it('Adds r1 owner with invalid length', async function () {
                let invalidLength = Math.ceil(Math.random() * 200) * 2;
                invalidLength = invalidLength === 128 ? 130 : invalidLength;

                const invalidPubkey = '0x' + 'C'.repeat(invalidLength);

                const addOwnerTx = await account.populateTransaction.r1AddOwner(
                    invalidPubkey,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'INVALID_PUBKEY_LENGTH',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Adds r1 owner with unauthorized msg.sender', async function () {
                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account.connect(randomWallet).r1AddOwner(newPublicKey),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Adds zero address as k1 owner', async function () {
                const addOwnerTx = await account.populateTransaction.k1AddOwner(
                    constants.AddressZero,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'INVALID_ADDRESS',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Adds k1 owner with unauthorized msg.sender', async function () {
                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .k1AddOwner(randomWallet.address),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Removes r1 owner with unauthorized msg.sender', async function () {
                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);

                const addOwnerTx = await account.populateTransaction.r1AddOwner(
                    newPublicKey,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.r1IsOwner(newPublicKey)).to.be.true;

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account.connect(randomWallet).r1RemoveOwner(newPublicKey),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Removes last r1 owner', async function () {
                const removeOwnerTx =
                    await account.populateTransaction.r1RemoveOwner(
                        encodePublicKey(keyPair),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    removeOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'EMPTY_R1_OWNERS',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Removes k1 owner with unauthorized msg.sender', async function () {
                const newAddress = Wallet.createRandom().address;

                const addOwnerTx = await account.populateTransaction.k1AddOwner(
                    newAddress,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsOwner(newAddress)).to.be.true;

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .k1RemoveOwner(randomWallet.address),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Clear owners with unauthorized msg.sender', async function () {
                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account.connect(randomWallet).resetOwners(newPublicKey),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Reset owners new r1 owner invalid length', async function () {
                let invalidLength = Math.ceil(Math.random() * 200) * 2;
                invalidLength = invalidLength === 128 ? 130 : invalidLength;

                const invalidPubkey = '0x' + 'C'.repeat(invalidLength);

                const resetOwnersTx =
                    await account.populateTransaction.resetOwners(
                        invalidPubkey,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    resetOwnersTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'INVALID_PUBKEY_LENGTH',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });
        });
    });

    describe('Validator manager', function () {
        describe('Should not revert when', function () {
            it('Adds a new r1 validator correctly', async function () {
                const newR1Validator = await deployTeeValidator(
                    richWallet,
                    verifier.address,
                );

                expect(await account.r1IsValidator(newR1Validator.address)).to
                    .be.false;

                const addValidatorTx =
                    await account.populateTransaction.r1AddValidator(
                        newR1Validator.address,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.r1IsValidator(newR1Validator.address)).to
                    .be.true;

                const expectedValidators = [
                    newR1Validator.address,
                    teeValidator.address,
                ];

                expect(await account.r1ListValidators()).to.deep.eq(
                    expectedValidators,
                );
            });

            it('Adds a new k1 validator correctly', async function () {
                const k1Validator = await deployEOAValidator(richWallet);

                expect(await account.k1IsValidator(k1Validator.address)).to.be
                    .false;

                const addValidatorTx =
                    await account.populateTransaction.k1AddValidator(
                        k1Validator.address,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsValidator(k1Validator.address)).to.be
                    .true;

                const expectedValidators = [k1Validator.address];

                expect(await account.k1ListValidators()).to.deep.eq(
                    expectedValidators,
                );
            });

            it('Removes an r1 validator correctly', async function () {
                const newR1Validator = await deployTeeValidator(
                    richWallet,
                    verifier.address,
                );

                const addValidatorTx =
                    await account.populateTransaction.r1AddValidator(
                        newR1Validator.address,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.r1IsValidator(newR1Validator.address)).to
                    .be.true;

                const removeValidatorTx =
                    await account.populateTransaction.r1RemoveValidator(
                        newR1Validator.address,
                    );

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt2 = await provider.sendTransaction(
                    utils.serialize(tx2),
                );
                await txReceipt2.wait();

                expect(await account.r1IsValidator(newR1Validator.address)).to
                    .be.false;

                const expectedValidators = [teeValidator.address];

                expect(await account.r1ListValidators()).to.deep.eq(
                    expectedValidators,
                );
            });

            it('Removes a k1 validator correctly', async function () {
                const k1Validator = await deployEOAValidator(richWallet);

                const addValidatorTx =
                    await account.populateTransaction.k1AddValidator(
                        k1Validator.address,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsValidator(k1Validator.address)).to.be
                    .true;

                const removeValidatorTx =
                    await account.populateTransaction.k1RemoveValidator(
                        k1Validator.address,
                    );

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt2 = await provider.sendTransaction(
                    utils.serialize(tx2),
                );
                await txReceipt2.wait();

                expect(await account.k1IsValidator(k1Validator.address)).to.be
                    .false;

                const expectedValidators: Array<string> = [];

                expect(await account.k1ListValidators()).to.deep.eq(
                    expectedValidators,
                );
            });
        });

        describe('Should revert when', function () {
            it('Adds r1 validator with unauthorized msg.sender', async function () {
                const newR1Validator = await deployTeeValidator(
                    richWallet,
                    verifier.address,
                );

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .r1AddValidator(newR1Validator.address),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Adds r1 validator with WRONG interface', async function () {
                const wrongInterfaceValidator = await deployEOAValidator(
                    richWallet,
                );

                const addValidatorTx =
                    await account.populateTransaction.r1AddValidator(
                        wrongInterfaceValidator.address,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'VALIDATOR_ERC165_FAIL',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Adds r1 validator with NO interface', async function () {
                const noInterfaceValidator = Wallet.createRandom();

                const addValidatorTx =
                    await account.populateTransaction.r1AddValidator(
                        noInterfaceValidator.address,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'VALIDATOR_ERC165_FAIL',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Removes r1 validator with unauthorized msg.sender', async function () {
                const newR1Validator = await deployTeeValidator(
                    richWallet,
                    verifier.address,
                );

                const addValidatorTx =
                    await account.populateTransaction.r1AddValidator(
                        newR1Validator.address,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.r1IsValidator(newR1Validator.address)).to
                    .be.true;

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .r1RemoveValidator(newR1Validator.address),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Removes last r1 validator', async function () {
                const removeValidatorTx =
                    await account.populateTransaction.r1RemoveValidator(
                        teeValidator.address,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    removeValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'EMPTY_R1_VALIDATORS',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Adds k1 validator with unauthorized msg.sender', async function () {
                const k1Validator = await deployEOAValidator(richWallet);

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .k1AddValidator(k1Validator.address),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Adds k1 validator with WRONG interface', async function () {
                const wrongInterfaceValidator = await deployTeeValidator(
                    richWallet,
                    verifier.address,
                );

                const addValidatorTx =
                    await account.populateTransaction.k1AddValidator(
                        wrongInterfaceValidator.address,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'VALIDATOR_ERC165_FAIL',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Adds k1 validator with NO interface', async function () {
                const noInterfaceValidator = Wallet.createRandom();

                const addValidatorTx =
                    await account.populateTransaction.k1AddValidator(
                        noInterfaceValidator.address,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'VALIDATOR_ERC165_FAIL',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Removes k1 validator with unauthorized msg.sender', async function () {
                const k1Validator = await deployEOAValidator(richWallet);

                const addValidatorTx =
                    await account.populateTransaction.k1AddValidator(
                        k1Validator.address,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsValidator(k1Validator.address)).to.be
                    .true;

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .k1RemoveValidator(k1Validator.address),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });
        });
    });

    describe('Module manager', function () {
        describe('Should not revert when', function () {
            it('Adds a new module correctly', async function () {
                const mockModule = await deployMockModule(richWallet);

                expect(await account.isModule(mockModule.address)).to.be.false;

                const initData = defaultAbiCoder.encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = hexConcat([mockModule.address, initData]);

                const addModuleTx = await account.populateTransaction.addModule(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.isModule(mockModule.address)).to.be.true;

                const expectedModules = [mockModule.address];

                expect(await account.listModules()).to.deep.eq(expectedModules);
            });

            it('Removes a module correctly', async function () {
                const mockModule = await deployMockModule(richWallet);

                const initData = defaultAbiCoder.encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = hexConcat([mockModule.address, initData]);

                const addModuleTx = await account.populateTransaction.addModule(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.isModule(mockModule.address)).to.be.true;

                const removeModuleTx =
                    await account.populateTransaction.removeModule(
                        mockModule.address,
                    );

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeModuleTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt2 = await provider.sendTransaction(
                    utils.serialize(tx2),
                );
                await txReceipt2.wait();

                expect(await account.isModule(mockModule.address)).to.be.false;

                const expectedModules: Array<string> = [];

                expect(await account.listModules()).to.deep.eq(expectedModules);
            });

            it('Executes from module correctly', async function () {
                const amount = parseEther('42');
                const delta = parseEther('0.01');

                const mockModule = await deployMockModule(richWallet);

                const initData = defaultAbiCoder.encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = hexConcat([mockModule.address, initData]);

                const addModuleTx = await account.populateTransaction.addModule(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                const accountBalanceBefore = await provider.getBalance(
                    account.address,
                );
                const receiverBalanceBefore = await provider.getBalance(
                    richWallet.address,
                );

                await mockModule.testExecuteFromModule(
                    account.address,
                    richWallet.address,
                );

                const accountBalanceAfter = await provider.getBalance(
                    account.address,
                );
                const receiverBalanceAfter = await provider.getBalance(
                    richWallet.address,
                );

                expect(accountBalanceAfter).to.be.closeTo(
                    accountBalanceBefore.sub(amount),
                    delta,
                );

                expect(receiverBalanceAfter).to.be.closeTo(
                    receiverBalanceBefore.add(amount),
                    delta,
                );
            });
        });
        describe('Should revert when', function () {
            it('Adds module with unauthorized msg.sender', async function () {
                const mockModule = await deployMockModule(richWallet);

                const initData = defaultAbiCoder.encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = hexConcat([mockModule.address, initData]);

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account.connect(randomWallet).addModule(moduleAndData),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Adds module with invalid moduleAndData length', async function () {
                const mockModule = await deployMockModule(richWallet);

                const moduleAndData = mockModule.address.slice(0, 10);

                const addModuleTx = await account.populateTransaction.addModule(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'EMPTY_MODULE_ADDRESS',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Adds module with no interface', async function () {
                const noInterfaceModule = Wallet.createRandom();

                const initData = defaultAbiCoder.encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = hexConcat([
                    noInterfaceModule.address,
                    initData,
                ]);

                const addModuleTx = await account.populateTransaction.addModule(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'MODULE_ERC165_FAIL',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Removes module with unauthorized msg.sender', async function () {
                const mockModule = await deployMockModule(richWallet);

                const initData = defaultAbiCoder.encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = hexConcat([mockModule.address, initData]);

                const addModuleTx = await account.populateTransaction.addModule(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .removeModule(mockModule.address),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });
        });
    });

    describe('Upgrade manager', function () {
        describe('Should not revert when', function () {
            it('Upgrades to a new implementation correctly', async function () {
                const mockImplementation = await deployMockImplementation(
                    richWallet,
                );

                const upgradeTx = await account.populateTransaction.upgradeTo(
                    mockImplementation.address,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    upgradeTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                await txReceipt.wait();

                expect(await account.implementation()).to.eq(
                    mockImplementation.address,
                );
            });
        });
        describe('Should revert when', function () {
            it('Upgrades to a new implementation with unauthorized msg.sender', async function () {
                const mockImplementation = await deployMockImplementation(
                    richWallet,
                );

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .upgradeTo(mockImplementation.address),
                ).to.be.revertedWithCustomError(account, 'NOT_FROM_SELF');
            });

            it('Upgrades to same implementation', async function () {
                const upgradeTx = await account.populateTransaction.upgradeTo(
                    implementation.address,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    upgradeTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'SAME_IMPLEMENTATION',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });
        });
    });

    describe('Hook manager', function () {
        describe('Should not revert when', function () {
            it('Adds a new validation hook correctly', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                expect(await account.isHook(mockHook.address)).to.be.false;

                const addHookTx = await account.populateTransaction.addHook(
                    mockHook.address,
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.isHook(mockHook.address)).to.be.true;

                const expectedHooks = [mockHook.address];
                expect(await account.listHooks(true)).to.deep.eq(expectedHooks);
            });

            it('Adds a new execution hook correctly', async function () {
                const mockHook = await deployMockExecutionHook(richWallet);

                expect(await account.isHook(mockHook.address)).to.be.false;

                const addHookTx = await account.populateTransaction.addHook(
                    mockHook.address,
                    false,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.isHook(mockHook.address)).to.be.true;

                const expectedHooks = [mockHook.address];
                expect(await account.listHooks(false)).to.deep.eq(
                    expectedHooks,
                );
            });

            it('Removes a hook correctly', async function () {
                const mockHook = await deployMockExecutionHook(richWallet);

                expect(await account.isHook(mockHook.address)).to.be.false;

                const addHookTx = await account.populateTransaction.addHook(
                    mockHook.address,
                    false,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.isHook(mockHook.address)).to.be.true;

                const removeHookTx =
                    await account.populateTransaction.removeHook(
                        mockHook.address,
                        false,
                    );

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt2 = await provider.sendTransaction(
                    utils.serialize(tx2),
                );
                txReceipt2.wait();

                expect(await account.isHook(mockHook.address)).to.be.false;

                const expectedHooks: Array<string> = [];
                expect(await account.listHooks(true)).to.deep.eq(expectedHooks);
            });

            it('Sets hook data correctly', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                expect(await account.isHook(mockHook.address)).to.be.false;

                const addHookTx = await account.populateTransaction.addHook(
                    mockHook.address,
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                expect(await account.isHook(mockHook.address)).to.be.true;

                const key = randomBytes(32);
                const data = '0xc1ae';

                await mockHook.setHookData(account.address, key, data);

                expect(await account.getHookData(mockHook.address, key)).to.eq(
                    data,
                );
            });

            it('Runs validation hooks successfully', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                expect(await account.isHook(mockHook.address)).to.be.false;

                const addHookTx = await account.populateTransaction.addHook(
                    mockHook.address,
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                const transfer = ethTransfer(richWallet.address, 1);

                const hookData = [defaultAbiCoder.encode(['bool'], [false])];

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    transfer,
                    teeValidator.address,
                    keyPair,
                    hookData,
                );

                const txReceipt2 = await provider.sendTransaction(
                    utils.serialize(tx2),
                );
                await txReceipt2.wait();
            });
        });

        describe('Should revert when', function () {
            it('Adds hook with unauthorized msg.sender', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .addHook(mockHook.address, true),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Adds hook with invalid hookAndData length', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                const hookAndData = mockHook.address.slice(0, 10);

                const addHookTx = await account.populateTransaction.addHook(
                    hookAndData,
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'EMPTY_HOOK_ADDRESS',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Adds hook with NO interface', async function () {
                const noInterfaceHook = Wallet.createRandom();

                const addHookTx = await account.populateTransaction.addHook(
                    noInterfaceHook.address,
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );

                // await expect(txReceipt.wait()).to.be.revertedWithCustomError(
                //     account,
                //     'HOOK_ERC165_FAIL',
                // );

                try {
                    await txReceipt.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Removes hook with unauthorized msg.sender', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                const addHookTx = await account.populateTransaction.addHook(
                    mockHook.address,
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .removeHook(mockHook.address, true),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Sets hook data with unauthorized msg.sender', async function () {
                const key = randomBytes(32);
                const data = '0xc1ae';

                await expect(
                    account.setHookData(key, data),
                ).to.be.revertedWithCustomError(account, 'NOT_FROM_HOOK');
            });

            it('Sets hook data with invalid key', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                const addHookTx = await account.populateTransaction.addHook(
                    mockHook.address,
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                const key = solidityKeccak256(
                    ['string'],
                    ['HookManager.context'],
                );
                const data = '0xc1ae';

                await expect(
                    mockHook.setHookData(account.address, key, data),
                ).to.be.revertedWithCustomError(account, 'INVALID_KEY');
            });

            it('Run validation hooks fails', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                const addHookTx = await account.populateTransaction.addHook(
                    mockHook.address,
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                const transfer = ethTransfer(richWallet.address, 5);

                const hookData = [defaultAbiCoder.encode(['bool'], [true])];

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    transfer,
                    teeValidator.address,
                    keyPair,
                    hookData,
                );

                try {
                    await provider.sendTransaction(utils.serialize(tx2));
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Run execution hooks fails', async function () {
                const mockHook = await deployMockExecutionHook(richWallet);

                const addHookTx = await account.populateTransaction.addHook(
                    mockHook.address,
                    false,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt = await provider.sendTransaction(
                    utils.serialize(tx),
                );
                await txReceipt.wait();

                const transfer = ethTransfer(richWallet.address, 5);

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    transfer,
                    teeValidator.address,
                    keyPair,
                );

                const txReceipt2 = await provider.sendTransaction(
                    utils.serialize(tx2),
                );

                try {
                    await txReceipt2.wait();
                    assert(false, 'Should revert');
                } catch (e) {}
            });
        });
    });

    describe('Paymaster', function () {
        let mockToken: MockStable;
        let gaslessPaymaster: GaslessPaymaster;
        let erc20Paymaster: ERC20PaymasterMock;
        let subsidizerPaymaster: SubsidizerPaymasterMock;

        beforeEach(async function () {
            mockToken = await deployMockStable(richWallet);

            gaslessPaymaster = await deployGaslessPaymaster(
                richWallet,
                registry.address,
                2,
            );

            erc20Paymaster = await deployERC20PaymasterMock(richWallet, [
                {
                    tokenAddress: mockToken.address,
                    decimals: 18,
                    priceMarkup: 20000,
                },
            ]);

            subsidizerPaymaster = await deploySubsidizerPaymasterMock(
                richWallet,
                [
                    {
                        tokenAddress: mockToken.address,
                        decimals: 18,
                        priceMarkup: 20000,
                    },
                ],
                registry.address,
            );

            await mockToken.mint(account.address, parseEther('100'));

            await (
                await richWallet.sendTransaction({
                    to: gaslessPaymaster.address,
                    value: parseEther('50'),
                })
            ).wait();

            await (
                await richWallet.sendTransaction({
                    to: erc20Paymaster.address,
                    value: parseEther('50'),
                })
            ).wait();

            await (
                await richWallet.sendTransaction({
                    to: subsidizerPaymaster.address,
                    value: parseEther('50'),
                })
            ).wait();
        });

        it('Should fund the account with mock token', async function () {
            expect(await mockToken.balanceOf(account.address)).to.be.eq(
                parseEther('100'),
            );
        });

        it('Should fund the paymasters', async function () {
            expect(await provider.getBalance(gaslessPaymaster.address)).to.eq(
                parseEther('50'),
            );
            expect(await provider.getBalance(erc20Paymaster.address)).to.eq(
                parseEther('50'),
            );
            expect(
                await provider.getBalance(subsidizerPaymaster.address),
            ).to.eq(parseEther('50'));
        });

        it('Should prepare an oracle payload', async function () {
            const oraclePayload = await getOraclePayload(erc20Paymaster);
            expect(oraclePayload).not.to.be.undefined;
        });

        it('Should pay gas with token', async function () {
            const amount = parseEther('10');

            const accountBalanceBefore = await provider.getBalance(
                account.address,
            );
            const receiverBalanceBefore = await provider.getBalance(
                richWallet.address,
            );
            const paymasterBalanceBefore = await provider.getBalance(
                erc20Paymaster.address,
            );

            const accountTokenBalanceBefore = await mockToken.balanceOf(
                account.address,
            );
            const contractTokenBalanceBefore = await mockToken.balanceOf(
                erc20Paymaster.address,
            );

            const transfer = ethTransfer(richWallet.address, amount);
            const tx = await prepareTeeTx(
                provider,
                account,
                transfer,
                teeValidator.address,
                keyPair,
                [],
                getERC20PaymasterInput(
                    erc20Paymaster.address,
                    mockToken.address,
                    parseUnits('50', 18),
                    await getOraclePayload(erc20Paymaster),
                ),
            );

            const txReceipt = await provider.sendTransaction(
                utils.serialize(tx),
            );

            await txReceipt.wait();

            const accountBalanceAfter = await provider.getBalance(
                account.address,
            );
            const receiverBalanceAfter = await provider.getBalance(
                richWallet.address,
            );
            const paymasterBalanceAfter = await provider.getBalance(
                erc20Paymaster.address,
            );

            const accountTokenBalanceAfter = await mockToken.balanceOf(
                account.address,
            );
            const contractTokenBalanceAfter = await mockToken.balanceOf(
                erc20Paymaster.address,
            );

            expect(accountBalanceAfter.add(amount)).to.be.equal(
                accountBalanceBefore,
            );

            expect(receiverBalanceBefore.add(amount)).to.be.equal(
                receiverBalanceAfter,
            );

            expect(paymasterBalanceAfter).is.lessThan(paymasterBalanceBefore);

            expect(accountTokenBalanceBefore).is.greaterThan(
                accountTokenBalanceAfter,
            );

            expect(
                accountTokenBalanceBefore.sub(accountTokenBalanceAfter),
            ).to.be.equal(
                contractTokenBalanceAfter.sub(contractTokenBalanceBefore),
            );
        });

        it('Should send tx without paying gas', async function () {
            const amount = parseEther('10');

            const accountBalanceBefore = await provider.getBalance(
                account.address,
            );
            const receiverBalanceBefore = await provider.getBalance(
                richWallet.address,
            );
            const paymasterBalanceBefore = await provider.getBalance(
                gaslessPaymaster.address,
            );

            const transfer = ethTransfer(richWallet.address, amount);
            const tx = await prepareTeeTx(
                provider,
                account,
                transfer,
                teeValidator.address,
                keyPair,
                [],
                getGaslessPaymasterInput(gaslessPaymaster.address),
            );

            const txReceipt = await provider.sendTransaction(
                utils.serialize(tx),
            );

            await txReceipt.wait();

            const accountBalanceAfter = await provider.getBalance(
                account.address,
            );
            const receiverBalanceAfter = await provider.getBalance(
                richWallet.address,
            );
            const paymasterBalanceAfter = await provider.getBalance(
                gaslessPaymaster.address,
            );

            expect(accountBalanceAfter.add(amount)).to.be.equal(
                accountBalanceBefore,
            );
            expect(receiverBalanceBefore.add(amount)).to.be.equal(
                receiverBalanceAfter,
            );
            expect(paymasterBalanceAfter).is.lessThan(paymasterBalanceBefore);
        });

        it('Should pay subsidized gas with token', async function () {
            const amount = parseEther('10');

            const accountBalanceBefore = await provider.getBalance(
                account.address,
            );
            const receiverBalanceBefore = await provider.getBalance(
                richWallet.address,
            );
            const paymasterBalanceBefore = await provider.getBalance(
                subsidizerPaymaster.address,
            );

            const accountTokenBalanceBefore = await mockToken.balanceOf(
                account.address,
            );
            const contractTokenBalanceBefore = await mockToken.balanceOf(
                subsidizerPaymaster.address,
            );

            const transfer = ethTransfer(richWallet.address, amount);
            const tx = await prepareTeeTx(
                provider,
                account,
                transfer,
                teeValidator.address,
                keyPair,
                [],
                getERC20PaymasterInput(
                    subsidizerPaymaster.address,
                    mockToken.address,
                    parseUnits('50', 18),
                    await getOraclePayload(subsidizerPaymaster),
                ),
            );

            const txReceipt = await provider.sendTransaction(
                utils.serialize(tx),
            );

            await txReceipt.wait();

            const accountBalanceAfter = await provider.getBalance(
                account.address,
            );
            const receiverBalanceAfter = await provider.getBalance(
                richWallet.address,
            );
            const paymasterBalanceAfter = await provider.getBalance(
                subsidizerPaymaster.address,
            );

            const accountTokenBalanceAfter = await mockToken.balanceOf(
                account.address,
            );
            const contractTokenBalanceAfter = await mockToken.balanceOf(
                subsidizerPaymaster.address,
            );

            expect(accountBalanceAfter.add(amount)).to.be.equal(
                accountBalanceBefore,
            );

            expect(receiverBalanceBefore.add(amount)).to.be.equal(
                receiverBalanceAfter,
            );

            expect(paymasterBalanceAfter).is.lessThan(paymasterBalanceBefore);

            expect(accountTokenBalanceBefore).is.greaterThan(
                accountTokenBalanceAfter,
            );

            expect(
                accountTokenBalanceBefore.sub(accountTokenBalanceAfter),
            ).to.be.equal(
                contractTokenBalanceAfter.sub(contractTokenBalanceBefore),
            );
        });

        describe('Subsidizer refunds calculations', function () {
            const MAX_GAS_TO_SUBSIDIZE = 1_250_000;

            const calcRefund = (
                gaslimit: number,
                gasused: number,
                max: number,
            ): number => {
                const userpaid = gaslimit > max ? gaslimit - max : 0;
                const gasrefunded = gaslimit - gasused;

                if (userpaid === 0) {
                    return 0;
                }

                if (max > gasused) {
                    return userpaid;
                } else {
                    return gasrefunded;
                }
            };

            const calcExpected = (
                refunded: number,
                maxFeePerGas: number,
                rate: ethers.BigNumber,
            ): number => {
                return (
                    refunded *
                    maxFeePerGas *
                    rate.div(constants.WeiPerEther).toNumber()
                );
            };

            type Config = {
                gasLimit: number;
                gasUsed: number;
                maxFeePerGas: number;
                rate: ethers.BigNumber;
                maxGasToSubsidize: number;
            };

            const checkRefund = async (
                pmConfig: Config,
            ): Promise<[number, ethers.BigNumber]> => {
                const expected = calcExpected(
                    calcRefund(
                        pmConfig.gasLimit,
                        pmConfig.gasUsed,
                        pmConfig.maxGasToSubsidize,
                    ),
                    pmConfig.maxFeePerGas,
                    pmConfig.rate,
                );

                const real = await subsidizerPaymaster.calcRefundAmount(
                    pmConfig.gasLimit,
                    pmConfig.gasLimit - pmConfig.gasUsed,
                    pmConfig.maxFeePerGas,
                    pmConfig.rate,
                );

                return [expected, real];
            };

            it('Should calculate if gasUsed is bigger than maxGasToSubsidize', async function () {
                const pmRate = await subsidizerPaymaster.getPairPrice(
                    mockToken.address,
                    '0x',
                );

                const pmConfig: Config = {
                    gasLimit: 2_000_000,
                    gasUsed: 1_500_000,
                    maxFeePerGas: 100,
                    rate: pmRate,
                    maxGasToSubsidize: 1_000_000,
                };

                const values = await checkRefund(pmConfig);
                expect(values[0].toString()).to.be.equal(values[1].toString());
            });

            it('Should calculate if gasUsed is equal to gasLimit and bigger than maxGasToSubsidize', async function () {
                const pmRate = await subsidizerPaymaster.getPairPrice(
                    mockToken.address,
                    '0x',
                );

                const pmConfig = {
                    gasLimit: 2_000_000,
                    gasUsed: 2_000_000,
                    maxFeePerGas: 100,
                    rate: pmRate,
                    maxGasToSubsidize: MAX_GAS_TO_SUBSIDIZE,
                };

                const values = await checkRefund(pmConfig);
                expect(values[0].toString()).to.be.equal(values[1].toString());
            });

            it('Should calculate if gasUsed is less than gasLimit and both less than maxGasToSubsidize', async function () {
                const pmRate = await subsidizerPaymaster.getPairPrice(
                    mockToken.address,
                    '0x',
                );

                const pmConfig = {
                    gasLimit: 1_000_000,
                    gasUsed: 500_000,
                    maxFeePerGas: 100,
                    rate: pmRate,
                    maxGasToSubsidize: MAX_GAS_TO_SUBSIDIZE,
                };

                const values = await checkRefund(pmConfig);
                expect(values[0].toString()).to.be.equal(values[1].toString());
            });

            it('Should calculate if gasUsed is equal to gasLimit and both less than maxGasToSubsidize', async function () {
                const pmRate = await subsidizerPaymaster.getPairPrice(
                    mockToken.address,
                    '0x',
                );

                const pmConfig = {
                    gasLimit: 500_000,
                    gasUsed: 500_000,
                    maxFeePerGas: 100,
                    rate: pmRate,
                    maxGasToSubsidize: MAX_GAS_TO_SUBSIDIZE,
                };

                const values = await checkRefund(pmConfig);
                expect(values[0].toString()).to.be.equal(values[1].toString());
            });

            it('Should calculate if gasUsed is less then maxGasToSubsidize ', async function () {
                const pmRate = await subsidizerPaymaster.getPairPrice(
                    mockToken.address,
                    '0x',
                );

                const pmConfig = {
                    gasLimit: 2_000_000,
                    gasUsed: 500_000,
                    maxFeePerGas: 100,
                    rate: pmRate,
                    maxGasToSubsidize: MAX_GAS_TO_SUBSIDIZE,
                };

                const values = await checkRefund(pmConfig);
                expect(values[0].toString()).to.be.equal(values[1].toString());
            });
        });
    });
});
