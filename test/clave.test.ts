/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { Contract } from '@ethersproject/contracts';
import { assert, expect } from 'chai';
import type { ec } from 'elliptic';
import {
    AbiCoder,
    WeiPerEther,
    ZeroAddress,
    concat,
    type ethers,
    parseEther,
    parseUnits,
    randomBytes,
    solidityPackedKeccak256,
} from 'ethers';
import { Provider, Wallet, utils } from 'zksync-ethers';

import type {
    AccountFactory,
    BatchCaller,
    ClaveImplementation,
    ClaveRegistry,
    MockStable,
    P256VerifierExpensive,
    TEEValidator,
} from '../typechain-types';
import {
    deployAccount,
    deployBatchCaller,
    deployEOAValidator,
    deployERC20PaymasterMock,
    deployETHDenverPaymaster,
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

async function getNonce(wallet: Wallet): Promise<number> {
    return await wallet.getNonce();
}

async function getContractNonce(account: Contract | unknown): Promise<number> {
    return await provider.getTransactionCount(
        await (account as Contract).getAddress(),
    );
}

async function waitTillNonceUpdate(
    wallet: Wallet,
    nonce: number,
): Promise<void> {
    while ((await wallet.getNonce()) === nonce) {
        await new Promise((resolve) => setTimeout(resolve, 100));
    }
}

async function waitTillNonceUpdateContract(
    account: Contract | unknown,
    nonce: number,
): Promise<void> {
    while (
        (await provider.getTransactionCount(
            await (account as Contract).getAddress(),
        )) === nonce
    ) {
        await new Promise((resolve) => setTimeout(resolve, 100));
    }
}

beforeEach(async () => {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    provider = new Provider(hre.network.config.url);
    richWallet = new Wallet(richPk, provider);

    keyPair = genKey();
    const publicKey = encodePublicKey(keyPair);

    let nonce = await getNonce(richWallet);
    batchCaller = await deployBatchCaller(richWallet);
    await waitTillNonceUpdate(richWallet, nonce);
    nonce = await getNonce(richWallet);
    verifier = await deployVerifier(richWallet);
    await waitTillNonceUpdate(richWallet, nonce);
    nonce = await getNonce(richWallet);
    teeValidator = await deployTeeValidator(
        richWallet,
        await verifier.getAddress(),
    );
    await waitTillNonceUpdate(richWallet, nonce);
    nonce = await getNonce(richWallet);
    implementation = await deployImplementation(
        richWallet,
        await batchCaller.getAddress(),
    );
    await waitTillNonceUpdate(richWallet, nonce);
    nonce = await getNonce(richWallet);
    registry = await deployRegistry(richWallet);
    await waitTillNonceUpdate(richWallet, nonce);
    nonce = await getNonce(richWallet);
    factory = await deployFactory(
        richWallet,
        await implementation.getAddress(),
        await registry.getAddress(),
    );
    await waitTillNonceUpdate(richWallet, nonce);
    nonce = await getNonce(richWallet);
    await registry.setFactory(await factory.getAddress());
    await waitTillNonceUpdate(richWallet, nonce);
    nonce = await getNonce(richWallet);
    account = await deployAccount(
        richWallet,
        await richWallet.getNonce(),
        factory,
        await teeValidator.getAddress(),
        publicKey,
    );
    await waitTillNonceUpdate(richWallet, nonce);
    nonce = await getNonce(richWallet);
    // 100 ETH transfered to Account
    await (
        await richWallet.sendTransaction({
            to: await account.getAddress(),
            value: parseEther('100'),
        })
    ).wait();
    await waitTillNonceUpdate(richWallet, nonce);
});

describe('Account no module no hook TEE validator', function () {
    describe('Should', function () {
        it('Have correct state after deployment', async function () {
            expect(await provider.getBalance(await account.getAddress())).to.eq(
                parseEther('100'),
            );

            const expectedR1Validators = [await teeValidator.getAddress()];
            const expectedK1Validators: Array<ethers.BytesLike> = [];
            const expectedR1Owners = [encodePublicKey(keyPair)];
            const expectedK1Owners: Array<ethers.BytesLike> = [];
            const expectedModules: Array<ethers.BytesLike> = [];
            const expectedHooks: Array<ethers.BytesLike> = [];
            const expectedImplementation = await implementation.getAddress();

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
            expect(await registry.isClave(await account.getAddress())).to.be
                .true;
        });

        it('Not show other contracts in registry', async function () {
            expect(await registry.isClave(await factory.getAddress())).not.to.be
                .true;
        });

        it('Transfer ETH correctly', async function () {
            const amount = parseEther('10');
            const delta = parseEther('0.01');

            const accountBalanceBefore = await provider.getBalance(
                await account.getAddress(),
            );
            const receiverBalanceBefore = await provider.getBalance(
                await richWallet.getAddress(),
            );

            const transfer = ethTransfer(await richWallet.getAddress(), amount);
            const tx = await prepareTeeTx(
                provider,
                account,
                transfer,
                await teeValidator.getAddress(),
                keyPair,
            );

            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );

            await txReceipt.wait();

            const accountBalanceAfter = await provider.getBalance(
                await account.getAddress(),
            );
            const receiverBalanceAfter = await provider.getBalance(
                await richWallet.getAddress(),
            );

            expect(accountBalanceAfter).to.be.closeTo(
                accountBalanceBefore - amount,
                delta,
            );

            expect(receiverBalanceAfter).to.eq(receiverBalanceBefore + amount);
        });

        it('Make batch transaction correctly', async function () {
            const accountBalanceBefore = await provider.getBalance(
                await account.getAddress(),
            );

            const receiver1 = await Wallet.createRandom().getAddress();
            const receiver2 = await Wallet.createRandom().getAddress();

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
                await batchCaller.getAddress(),
                calls,
                await teeValidator.getAddress(),
                keyPair,
            );

            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(batchTx),
            );
            await txReceipt.wait();

            const accountBalanceAfter = await provider.getBalance(
                await account.getAddress(),
            );

            expect(accountBalanceAfter).to.be.closeTo(
                accountBalanceBefore - parseEther('0.3'),
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

                const addOwnerTx = await account.r1AddOwner.populateTransaction(
                    newPublicKey,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    await teeValidator.getAddress(),
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

            it('Removes an r1 owner correctly', async function () {
                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);

                const addOwnerTx = await account.r1AddOwner.populateTransaction(
                    newPublicKey,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.r1IsOwner(newPublicKey)).to.be.true;

                const removeOwnerTx =
                    await account.r1RemoveOwner.populateTransaction(
                        newPublicKey,
                    );

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeOwnerTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt2 = await provider.broadcastTransaction(
                    utils.serializeEip712(tx2),
                );
                await txReceipt2.wait();

                expect(await account.r1IsOwner(newPublicKey)).to.be.false;

                const expectedOwners = [encodePublicKey(keyPair)];

                expect(await account.r1ListOwners()).to.deep.eq(expectedOwners);
            });

            it('Adds a new k1 owner correctly', async function () {
                const newAddress = await Wallet.createRandom().getAddress();

                expect(await account.k1IsOwner(newAddress)).to.be.false;

                const addOwnerTx = await account.k1AddOwner.populateTransaction(
                    newAddress,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsOwner(newAddress)).to.be.true;

                const expectedOwners = [newAddress];

                expect(await account.k1ListOwners()).to.deep.eq(expectedOwners);
            });

            it('Removes a k1 owner correctly', async function () {
                const newAddress = await Wallet.createRandom().getAddress();

                const addOwnerTx = await account.k1AddOwner.populateTransaction(
                    newAddress,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsOwner(newAddress)).to.be.true;

                const removeOwnerTx =
                    await account.k1RemoveOwner.populateTransaction(newAddress);

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeOwnerTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt2 = await provider.broadcastTransaction(
                    utils.serializeEip712(tx2),
                );
                await txReceipt2.wait();

                expect(await account.k1IsOwner(newAddress)).to.be.false;

                const expectedOwners: Array<string> = [];

                expect(await account.k1ListOwners()).to.deep.eq(expectedOwners);
            });

            it('Resets owners correctly', async function () {
                const newAddress = await Wallet.createRandom().getAddress();

                const addOwnerTx = await account.k1AddOwner.populateTransaction(
                    newAddress,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsOwner(newAddress)).to.be.true;

                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);

                const resetOwnersTx =
                    await account.resetOwners.populateTransaction(newPublicKey);

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    resetOwnersTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt2 = await provider.broadcastTransaction(
                    utils.serializeEip712(tx2),
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

                const addOwnerTx = await account.r1AddOwner.populateTransaction(
                    invalidPubkey,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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

            it('Adds await zero getAddress() as k1 owner', async function () {
                const addOwnerTx = await account.k1AddOwner.populateTransaction(
                    ZeroAddress,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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
                        .k1AddOwner(await randomWallet.getAddress()),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Removes r1 owner with unauthorized msg.sender', async function () {
                const newKeyPair = genKey();
                const newPublicKey = encodePublicKey(newKeyPair);

                const addOwnerTx = await account.r1AddOwner.populateTransaction(
                    newPublicKey,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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
                    await account.r1RemoveOwner.populateTransaction(
                        encodePublicKey(keyPair),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    removeOwnerTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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
                const newAddress = await Wallet.createRandom().getAddress();

                const addOwnerTx = await account.k1AddOwner.populateTransaction(
                    newAddress,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addOwnerTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.k1IsOwner(newAddress)).to.be.true;

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .k1RemoveOwner(await randomWallet.getAddress()),
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
                    await account.resetOwners.populateTransaction(
                        invalidPubkey,
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    resetOwnersTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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
                    await verifier.getAddress(),
                );

                expect(
                    await account.r1IsValidator(
                        await newR1Validator.getAddress(),
                    ),
                ).to.be.false;

                const addValidatorTx =
                    await account.r1AddValidator.populateTransaction(
                        await newR1Validator.getAddress(),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(
                    await account.r1IsValidator(
                        await newR1Validator.getAddress(),
                    ),
                ).to.be.true;

                const expectedValidators = [
                    await newR1Validator.getAddress(),
                    await teeValidator.getAddress(),
                ];

                expect(await account.r1ListValidators()).to.deep.eq(
                    expectedValidators,
                );
            });

            it('Adds a new k1 validator correctly', async function () {
                const k1Validator = await deployEOAValidator(richWallet);

                expect(
                    await account.k1IsValidator(await k1Validator.getAddress()),
                ).to.be.false;

                const addValidatorTx =
                    await account.k1AddValidator.populateTransaction(
                        await k1Validator.getAddress(),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(
                    await account.k1IsValidator(await k1Validator.getAddress()),
                ).to.be.true;

                const expectedValidators = [await k1Validator.getAddress()];

                expect(await account.k1ListValidators()).to.deep.eq(
                    expectedValidators,
                );
            });

            it('Removes an r1 validator correctly', async function () {
                const newR1Validator = await deployTeeValidator(
                    richWallet,
                    await verifier.getAddress(),
                );

                const addValidatorTx =
                    await account.r1AddValidator.populateTransaction(
                        await newR1Validator.getAddress(),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(
                    await account.r1IsValidator(
                        await newR1Validator.getAddress(),
                    ),
                ).to.be.true;

                const removeValidatorTx =
                    await account.r1RemoveValidator.populateTransaction(
                        await newR1Validator.getAddress(),
                    );

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt2 = await provider.broadcastTransaction(
                    utils.serializeEip712(tx2),
                );
                await txReceipt2.wait();

                expect(
                    await account.r1IsValidator(
                        await newR1Validator.getAddress(),
                    ),
                ).to.be.false;

                const expectedValidators = [await teeValidator.getAddress()];

                expect(await account.r1ListValidators()).to.deep.eq(
                    expectedValidators,
                );
            });

            it('Removes a k1 validator correctly', async function () {
                const k1Validator = await deployEOAValidator(richWallet);

                const addValidatorTx =
                    await account.k1AddValidator.populateTransaction(
                        await k1Validator.getAddress(),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(
                    await account.k1IsValidator(await k1Validator.getAddress()),
                ).to.be.true;

                const removeValidatorTx =
                    await account.k1RemoveValidator.populateTransaction(
                        await k1Validator.getAddress(),
                    );

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt2 = await provider.broadcastTransaction(
                    utils.serializeEip712(tx2),
                );
                await txReceipt2.wait();

                expect(
                    await account.k1IsValidator(await k1Validator.getAddress()),
                ).to.be.false;

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
                    await verifier.getAddress(),
                );

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .r1AddValidator(await newR1Validator.getAddress()),
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
                    await account.r1AddValidator.populateTransaction(
                        await wrongInterfaceValidator.getAddress(),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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
                    await account.r1AddValidator.populateTransaction(
                        await noInterfaceValidator.getAddress(),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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
                    await verifier.getAddress(),
                );

                const addValidatorTx =
                    await account.r1AddValidator.populateTransaction(
                        await newR1Validator.getAddress(),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(
                    await account.r1IsValidator(
                        await newR1Validator.getAddress(),
                    ),
                ).to.be.true;

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .r1RemoveValidator(await newR1Validator.getAddress()),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Removes last r1 validator', async function () {
                const removeValidatorTx =
                    await account.r1RemoveValidator.populateTransaction(
                        await teeValidator.getAddress(),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    removeValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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
                        .k1AddValidator(await k1Validator.getAddress()),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Adds k1 validator with WRONG interface', async function () {
                const wrongInterfaceValidator = await deployTeeValidator(
                    richWallet,
                    await verifier.getAddress(),
                );

                const addValidatorTx =
                    await account.k1AddValidator.populateTransaction(
                        await wrongInterfaceValidator.getAddress(),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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
                    await account.k1AddValidator.populateTransaction(
                        await noInterfaceValidator.getAddress(),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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
                    await account.k1AddValidator.populateTransaction(
                        await k1Validator.getAddress(),
                    );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addValidatorTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(
                    await account.k1IsValidator(await k1Validator.getAddress()),
                ).to.be.true;

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .k1RemoveValidator(await k1Validator.getAddress()),
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

                expect(await account.isModule(await mockModule.getAddress())).to
                    .be.false;

                const initData = AbiCoder.defaultAbiCoder().encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = concat([
                    await mockModule.getAddress(),
                    initData,
                ]);

                const addModuleTx = await account.addModule.populateTransaction(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.isModule(await mockModule.getAddress())).to
                    .be.true;

                const expectedModules = [await mockModule.getAddress()];

                expect(await account.listModules()).to.deep.eq(expectedModules);
            });

            it('Removes a module correctly', async function () {
                const mockModule = await deployMockModule(richWallet);

                const initData = AbiCoder.defaultAbiCoder().encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = concat([
                    await mockModule.getAddress(),
                    initData,
                ]);

                const addModuleTx = await account.addModule.populateTransaction(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.isModule(await mockModule.getAddress())).to
                    .be.true;

                const removeModuleTx =
                    await account.removeModule.populateTransaction(
                        await mockModule.getAddress(),
                    );

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeModuleTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt2 = await provider.broadcastTransaction(
                    utils.serializeEip712(tx2),
                );
                await txReceipt2.wait();

                expect(await account.isModule(await mockModule.getAddress())).to
                    .be.false;

                const expectedModules: Array<string> = [];

                expect(await account.listModules()).to.deep.eq(expectedModules);
            });

            it('Executes from module correctly', async function () {
                const amount = parseEther('42');
                const delta = parseEther('0.01');

                const mockModule = await deployMockModule(richWallet);

                const initData = AbiCoder.defaultAbiCoder().encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = concat([
                    await mockModule.getAddress(),
                    initData,
                ]);

                const addModuleTx = await account.addModule.populateTransaction(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                const accountBalanceBefore = await provider.getBalance(
                    await account.getAddress(),
                );
                const receiverBalanceBefore = await provider.getBalance(
                    await richWallet.getAddress(),
                );

                await mockModule.testExecuteFromModule(
                    await account.getAddress(),
                    await richWallet.getAddress(),
                );

                const accountBalanceAfter = await provider.getBalance(
                    await account.getAddress(),
                );
                const receiverBalanceAfter = await provider.getBalance(
                    await richWallet.getAddress(),
                );

                expect(accountBalanceAfter).to.be.closeTo(
                    accountBalanceBefore - amount,
                    delta,
                );

                expect(receiverBalanceAfter).to.be.closeTo(
                    receiverBalanceBefore + amount,
                    delta,
                );
            });
        });
        describe('Should revert when', function () {
            it('Adds module with unauthorized msg.sender', async function () {
                const mockModule = await deployMockModule(richWallet);

                const initData = AbiCoder.defaultAbiCoder().encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = concat([
                    await mockModule.getAddress(),
                    initData,
                ]);

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

                const moduleAndData = (await mockModule.getAddress()).slice(
                    0,
                    10,
                );

                const addModuleTx = await account.addModule.populateTransaction(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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

                const initData = AbiCoder.defaultAbiCoder().encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = concat([
                    await noInterfaceModule.getAddress(),
                    initData,
                ]);

                const addModuleTx = await account.addModule.populateTransaction(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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

                const initData = AbiCoder.defaultAbiCoder().encode(
                    ['uint256'],
                    [parseEther('42')],
                );
                const moduleAndData = concat([
                    await mockModule.getAddress(),
                    initData,
                ]);

                const addModuleTx = await account.addModule.populateTransaction(
                    moduleAndData,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addModuleTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .removeModule(await mockModule.getAddress()),
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

                const upgradeTx = await account.upgradeTo.populateTransaction(
                    await mockImplementation.getAddress(),
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    upgradeTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );

                await txReceipt.wait();

                expect(await account.implementation()).to.eq(
                    await mockImplementation.getAddress(),
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
                        .upgradeTo(await mockImplementation.getAddress()),
                ).to.be.revertedWithCustomError(account, 'NOT_FROM_SELF');
            });

            it('Upgrades to same implementation', async function () {
                const upgradeTx = await account.upgradeTo.populateTransaction(
                    await implementation.getAddress(),
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    upgradeTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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

                expect(await account.isHook(await mockHook.getAddress())).to.be
                    .false;

                const addHookTx = await account.addHook.populateTransaction(
                    await mockHook.getAddress(),
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.isHook(await mockHook.getAddress())).to.be
                    .true;

                const expectedHooks = [await mockHook.getAddress()];
                expect(await account.listHooks(true)).to.deep.eq(expectedHooks);
            });

            it('Adds a new execution hook correctly', async function () {
                const mockHook = await deployMockExecutionHook(richWallet);

                expect(await account.isHook(await mockHook.getAddress())).to.be
                    .false;

                const addHookTx = await account.addHook.populateTransaction(
                    await mockHook.getAddress(),
                    false,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.isHook(await mockHook.getAddress())).to.be
                    .true;

                const expectedHooks = [await mockHook.getAddress()];
                expect(await account.listHooks(false)).to.deep.eq(
                    expectedHooks,
                );
            });

            it('Removes a hook correctly', async function () {
                const mockHook = await deployMockExecutionHook(richWallet);

                expect(await account.isHook(await mockHook.getAddress())).to.be
                    .false;

                const addHookTx = await account.addHook.populateTransaction(
                    await mockHook.getAddress(),
                    false,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.isHook(await mockHook.getAddress())).to.be
                    .true;

                const removeHookTx =
                    await account.removeHook.populateTransaction(
                        await mockHook.getAddress(),
                        false,
                    );

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    removeHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt2 = await provider.broadcastTransaction(
                    utils.serializeEip712(tx2),
                );
                txReceipt2.wait();

                expect(await account.isHook(await mockHook.getAddress())).to.be
                    .false;

                const expectedHooks: Array<string> = [];
                expect(await account.listHooks(true)).to.deep.eq(expectedHooks);
            });

            it('Sets hook data correctly', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                expect(await account.isHook(await mockHook.getAddress())).to.be
                    .false;

                const addHookTx = await account.addHook.populateTransaction(
                    await mockHook.getAddress(),
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                expect(await account.isHook(await mockHook.getAddress())).to.be
                    .true;

                const key = randomBytes(32);
                const data = '0xc1ae';

                await mockHook.setHookData(
                    await account.getAddress(),
                    key,
                    data,
                );

                expect(
                    await account.getHookData(await mockHook.getAddress(), key),
                ).to.eq(data);
            });

            it('Runs validation hooks successfully', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                expect(await account.isHook(await mockHook.getAddress())).to.be
                    .false;

                const addHookTx = await account.addHook.populateTransaction(
                    await mockHook.getAddress(),
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                const transfer = ethTransfer(await richWallet.getAddress(), 1);

                const hookData = [
                    AbiCoder.defaultAbiCoder().encode(['bool'], [false]),
                ];

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    transfer,
                    await teeValidator.getAddress(),
                    keyPair,
                    hookData,
                );

                const txReceipt2 = await provider.broadcastTransaction(
                    utils.serializeEip712(tx2),
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
                        .addHook(await mockHook.getAddress(), true),
                ).to.be.revertedWithCustomError(
                    account,
                    'NOT_FROM_SELF_OR_MODULE',
                );
            });

            it('Adds hook with invalid hookAndData length', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                const hookAndData = (await mockHook.getAddress()).slice(0, 10);

                const addHookTx = await account.addHook.populateTransaction(
                    hookAndData,
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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

                const addHookTx = await account.addHook.populateTransaction(
                    await noInterfaceHook.getAddress(),
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
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

                const addHookTx = await account.addHook.populateTransaction(
                    await mockHook.getAddress(),
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                const randomWallet = Wallet.createRandom().connect(provider);

                await expect(
                    account
                        .connect(randomWallet)
                        .removeHook(await mockHook.getAddress(), true),
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

                const addHookTx = await account.addHook.populateTransaction(
                    await mockHook.getAddress(),
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                const key = solidityPackedKeccak256(
                    ['string'],
                    ['HookManager.context'],
                );
                const data = '0xc1ae';

                await expect(
                    mockHook.setHookData(await account.getAddress(), key, data),
                ).to.be.revertedWithCustomError(account, 'INVALID_KEY');
            });

            it('Run validation hooks fails', async function () {
                const mockHook = await deployMockValidationHook(richWallet);

                const addHookTx = await account.addHook.populateTransaction(
                    await mockHook.getAddress(),
                    true,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                const transfer = ethTransfer(await richWallet.getAddress(), 5);

                const hookData = [
                    AbiCoder.defaultAbiCoder().encode(['bool'], [true]),
                ];

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    transfer,
                    await teeValidator.getAddress(),
                    keyPair,
                    hookData,
                );

                try {
                    await provider.broadcastTransaction(
                        utils.serializeEip712(tx2),
                    );
                    assert(false, 'Should revert');
                } catch (e) {}
            });

            it('Run execution hooks fails', async function () {
                const mockHook = await deployMockExecutionHook(richWallet);

                const addHookTx = await account.addHook.populateTransaction(
                    await mockHook.getAddress(),
                    false,
                );

                const tx = await prepareTeeTx(
                    provider,
                    account,
                    addHookTx,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt = await provider.broadcastTransaction(
                    utils.serializeEip712(tx),
                );
                await txReceipt.wait();

                const transfer = ethTransfer(await richWallet.getAddress(), 5);

                const tx2 = await prepareTeeTx(
                    provider,
                    account,
                    transfer,
                    await teeValidator.getAddress(),
                    keyPair,
                );

                const txReceipt2 = await provider.broadcastTransaction(
                    utils.serializeEip712(tx2),
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
        let gaslessPaymaster: Contract;
        let erc20Paymaster: Contract;
        let subsidizerPaymaster: Contract;
        let ethdenverPaymaster: Contract;

        beforeEach(async function () {
            let nonce = await getNonce(richWallet);
            mockToken = await deployMockStable(richWallet);
            await waitTillNonceUpdate(richWallet, nonce);

            nonce = await getNonce(richWallet);
            gaslessPaymaster = await deployGaslessPaymaster(
                richWallet,
                await registry.getAddress(),
                2,
            );
            await waitTillNonceUpdate(richWallet, nonce);

            nonce = await getNonce(richWallet);
            erc20Paymaster = await deployERC20PaymasterMock(richWallet, [
                {
                    tokenAddress: await mockToken.getAddress(),
                    decimals: 18,
                    priceMarkup: 20000,
                },
            ]);
            await waitTillNonceUpdate(richWallet, nonce);

            nonce = await getNonce(richWallet);
            subsidizerPaymaster = await deploySubsidizerPaymasterMock(
                richWallet,
                [
                    {
                        tokenAddress: await mockToken.getAddress(),
                        decimals: 18,
                        priceMarkup: 20000,
                    },
                ],
                await registry.getAddress(),
            );
            await waitTillNonceUpdate(richWallet, nonce);

            nonce = await getNonce(richWallet);
            ethdenverPaymaster = await deployETHDenverPaymaster(
                richWallet,
                await registry.getAddress(),
                2,
                await mockToken.getAddress(),
            );
            await waitTillNonceUpdate(richWallet, nonce);

            nonce = await getNonce(richWallet);
            await mockToken.mint(await account.getAddress(), parseEther('100'));
            await waitTillNonceUpdate(richWallet, nonce);

            nonce = await getNonce(richWallet);
            await (
                await richWallet.sendTransaction({
                    to: gaslessPaymaster.address,
                    value: parseEther('50'),
                })
            ).wait();
            await waitTillNonceUpdate(richWallet, nonce);

            nonce = await getNonce(richWallet);
            await (
                await richWallet.sendTransaction({
                    to: erc20Paymaster.address,
                    value: parseEther('50'),
                })
            ).wait();
            await waitTillNonceUpdate(richWallet, nonce);

            nonce = await getNonce(richWallet);
            await (
                await richWallet.sendTransaction({
                    to: subsidizerPaymaster.address,
                    value: parseEther('50'),
                })
            ).wait();
            await waitTillNonceUpdate(richWallet, nonce);

            nonce = await getNonce(richWallet);
            await (
                await richWallet.sendTransaction({
                    to: ethdenverPaymaster.address,
                    value: parseEther('50'),
                })
            ).wait();
            await waitTillNonceUpdate(richWallet, nonce);
        });

        it('Should fund the account with mock token', async function () {
            expect(
                await mockToken.balanceOf(await account.getAddress()),
            ).to.be.eq(parseEther('100'));
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
            expect(await provider.getBalance(ethdenverPaymaster.address)).to.eq(
                parseEther('50'),
            );
        });

        it('Should prepare an oracle payload', async function () {
            const oraclePayload = await getOraclePayload(erc20Paymaster);
            expect(oraclePayload).not.to.be.undefined;
        });

        it('Should pay gas with token', async function () {
            const amount = parseEther('10');

            const accountBalanceBefore = await provider.getBalance(
                await account.getAddress(),
            );
            const receiverBalanceBefore = await provider.getBalance(
                await richWallet.getAddress(),
            );
            const paymasterBalanceBefore = await provider.getBalance(
                erc20Paymaster.address,
            );

            const accountTokenBalanceBefore = await mockToken.balanceOf(
                await account.getAddress(),
            );
            const contractTokenBalanceBefore = await mockToken.balanceOf(
                erc20Paymaster.address,
            );

            const transfer = ethTransfer(await richWallet.getAddress(), amount);
            const tx = await prepareTeeTx(
                provider,
                account,
                transfer,
                await teeValidator.getAddress(),
                keyPair,
                [],
                getERC20PaymasterInput(
                    erc20Paymaster.address,
                    await mockToken.getAddress(),
                    parseUnits('50', 18),
                    await getOraclePayload(erc20Paymaster),
                ),
            );

            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );

            await txReceipt.wait();

            const accountBalanceAfter = await provider.getBalance(
                await account.getAddress(),
            );
            const receiverBalanceAfter = await provider.getBalance(
                await richWallet.getAddress(),
            );
            const paymasterBalanceAfter = await provider.getBalance(
                erc20Paymaster.address,
            );

            const accountTokenBalanceAfter = await mockToken.balanceOf(
                await account.getAddress(),
            );
            const contractTokenBalanceAfter = await mockToken.balanceOf(
                erc20Paymaster.address,
            );

            expect(accountBalanceAfter + amount).to.be.equal(
                accountBalanceBefore,
            );

            expect(receiverBalanceBefore + amount).to.be.equal(
                receiverBalanceAfter,
            );

            expect(paymasterBalanceAfter).is.lessThan(paymasterBalanceBefore);

            expect(accountTokenBalanceBefore).is.greaterThan(
                accountTokenBalanceAfter,
            );

            expect(
                accountTokenBalanceBefore - accountTokenBalanceAfter,
            ).to.be.equal(
                contractTokenBalanceAfter - contractTokenBalanceBefore,
            );
        });

        it('Should send tx without paying gas', async function () {
            const amount = parseEther('10');

            const accountBalanceBefore = await provider.getBalance(
                await account.getAddress(),
            );
            const receiverBalanceBefore = await provider.getBalance(
                await richWallet.getAddress(),
            );
            const paymasterBalanceBefore = await provider.getBalance(
                gaslessPaymaster.address,
            );

            const transfer = ethTransfer(await richWallet.getAddress(), amount);
            const tx = await prepareTeeTx(
                provider,
                account,
                transfer,
                await teeValidator.getAddress(),
                keyPair,
                [],
                getGaslessPaymasterInput(gaslessPaymaster.address),
            );

            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );

            await txReceipt.wait();

            const accountBalanceAfter = await provider.getBalance(
                await account.getAddress(),
            );
            const receiverBalanceAfter = await provider.getBalance(
                await richWallet.getAddress(),
            );
            const paymasterBalanceAfter = await provider.getBalance(
                gaslessPaymaster.address,
            );

            expect(accountBalanceAfter + amount).to.be.equal(
                accountBalanceBefore,
            );
            expect(receiverBalanceBefore + amount).to.be.equal(
                receiverBalanceAfter,
            );
            expect(paymasterBalanceAfter).is.lessThan(paymasterBalanceBefore);
        });

        it('Should pay subsidized gas with token', async function () {
            const amount = parseEther('10');

            const accountBalanceBefore = await provider.getBalance(
                await account.getAddress(),
            );
            const receiverBalanceBefore = await provider.getBalance(
                await richWallet.getAddress(),
            );
            const paymasterBalanceBefore = await provider.getBalance(
                subsidizerPaymaster.address,
            );

            const accountTokenBalanceBefore = await mockToken.balanceOf(
                await account.getAddress(),
            );
            const contractTokenBalanceBefore = await mockToken.balanceOf(
                subsidizerPaymaster.address,
            );

            const transfer = ethTransfer(await richWallet.getAddress(), amount);
            const tx = await prepareTeeTx(
                provider,
                account,
                transfer,
                await teeValidator.getAddress(),
                keyPair,
                [],
                getERC20PaymasterInput(
                    subsidizerPaymaster.address,
                    await mockToken.getAddress(),
                    parseUnits('50', 18),
                    await getOraclePayload(subsidizerPaymaster),
                ),
            );

            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );

            await txReceipt.wait();

            const accountBalanceAfter = await provider.getBalance(
                await account.getAddress(),
            );
            const receiverBalanceAfter = await provider.getBalance(
                await richWallet.getAddress(),
            );
            const paymasterBalanceAfter = await provider.getBalance(
                subsidizerPaymaster.address,
            );

            const accountTokenBalanceAfter = await mockToken.balanceOf(
                await account.getAddress(),
            );
            const contractTokenBalanceAfter = await mockToken.balanceOf(
                subsidizerPaymaster.address,
            );

            expect(accountBalanceAfter + amount).to.be.equal(
                accountBalanceBefore,
            );

            expect(receiverBalanceBefore + amount).to.be.equal(
                receiverBalanceAfter,
            );

            expect(paymasterBalanceAfter).is.lessThan(paymasterBalanceBefore);

            expect(accountTokenBalanceBefore).is.greaterThan(
                accountTokenBalanceAfter,
            );

            expect(
                accountTokenBalanceBefore - accountTokenBalanceAfter,
            ).to.be.equal(
                contractTokenBalanceAfter - contractTokenBalanceBefore,
            );
        });

        describe('Subsidizer refunds calculations', function () {
            const MAX_GAS_TO_SUBSIDIZE = 1_250_000n;

            const calcRefund = (
                gaslimit: bigint,
                gasused: bigint,
                max: bigint,
            ): bigint => {
                const userpaid = gaslimit > max ? gaslimit - max : 0;
                const gasrefunded = gaslimit - gasused;

                if (userpaid === 0) {
                    return 0n;
                }

                if (max > gasused) {
                    return userpaid;
                } else {
                    return gasrefunded;
                }
            };

            const calcExpected = (
                refunded: bigint,
                maxFeePerGas: bigint,
                rate: bigint,
            ): bigint => {
                return (refunded * maxFeePerGas * rate) / WeiPerEther;
            };

            type Config = {
                gasLimit: bigint;
                gasUsed: bigint;
                maxFeePerGas: bigint;
                rate: bigint;
                maxGasToSubsidize: bigint;
            };

            const checkRefund = async (
                pmConfig: Config,
            ): Promise<[bigint, bigint]> => {
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
                    await mockToken.getAddress(),
                    '0x',
                );

                const pmConfig: Config = {
                    gasLimit: 2_000_000n,
                    gasUsed: 1_500_000n,
                    maxFeePerGas: 100n,
                    rate: BigInt(pmRate.toString()),
                    maxGasToSubsidize: 1_000_000n,
                };

                const values = await checkRefund(pmConfig);
                expect(values[0]).to.be.equal(values[1]);
            });

            it('Should calculate if gasUsed is equal to gasLimit and bigger than maxGasToSubsidize', async function () {
                const pmRate = await subsidizerPaymaster.getPairPrice(
                    await mockToken.getAddress(),
                    '0x',
                );

                const pmConfig = {
                    gasLimit: 2_000_000n,
                    gasUsed: 2_000_000n,
                    maxFeePerGas: 100n,
                    rate: BigInt(pmRate.toString()),
                    maxGasToSubsidize: MAX_GAS_TO_SUBSIDIZE,
                };

                const values = await checkRefund(pmConfig);
                expect(values[0]).to.be.equal(values[1]);
            });

            it('Should calculate if gasUsed is less than gasLimit and both less than maxGasToSubsidize', async function () {
                const pmRate = await subsidizerPaymaster.getPairPrice(
                    await mockToken.getAddress(),
                    '0x',
                );

                const pmConfig = {
                    gasLimit: 1_000_000n,
                    gasUsed: 500_000n,
                    maxFeePerGas: 100n,
                    rate: BigInt(pmRate.toString()),
                    maxGasToSubsidize: MAX_GAS_TO_SUBSIDIZE,
                };

                const values = await checkRefund(pmConfig);
                expect(values[0]).to.be.equal(values[1]);
            });

            it('Should calculate if gasUsed is equal to gasLimit and both less than maxGasToSubsidize', async function () {
                const pmRate = await subsidizerPaymaster.getPairPrice(
                    await mockToken.getAddress(),
                    '0x',
                );

                const pmConfig = {
                    gasLimit: 500_000n,
                    gasUsed: 500_000n,
                    maxFeePerGas: 100n,
                    rate: BigInt(pmRate.toString()),
                    maxGasToSubsidize: MAX_GAS_TO_SUBSIDIZE,
                };

                const values = await checkRefund(pmConfig);
                expect(values[0]).to.be.equal(values[1]);
            });

            it('Should calculate if gasUsed is less then maxGasToSubsidize ', async function () {
                const pmRate = await subsidizerPaymaster.getPairPrice(
                    await mockToken.getAddress(),
                    '0x',
                );

                const pmConfig = {
                    gasLimit: 2_000_000n,
                    gasUsed: 500_000n,
                    maxFeePerGas: 100n,
                    rate: BigInt(pmRate.toString()),
                    maxGasToSubsidize: MAX_GAS_TO_SUBSIDIZE,
                };

                const values = await checkRefund(pmConfig);
                expect(values[0]).to.be.equal(values[1]);
            });
        });

        it('Should start with two limit', async function () {
            const address = await richWallet.getAddress();
            const limit = await ethdenverPaymaster.getRemainingUserLimit(
                address,
            );

            expect(limit).to.be.equal(2n);
        });

        it('Should send tx without paying gas and decreases the limit', async function () {
            const address = await account.getAddress();
            const prevlimit = await ethdenverPaymaster.getRemainingUserLimit(
                address,
            );

            const amount = parseEther('10');
            const transfer = ethTransfer(await richWallet.getAddress(), amount);
            const tx = await prepareTeeTx(
                provider,
                account,
                transfer,
                await teeValidator.getAddress(),
                keyPair,
                [],
                getGaslessPaymasterInput(ethdenverPaymaster.address),
            );

            const nonce = await getContractNonce(account);
            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );
            await txReceipt.wait();
            await waitTillNonceUpdateContract(account, nonce);

            const afterlimit = await ethdenverPaymaster.getRemainingUserLimit(
                address,
            );

            expect(Number(prevlimit.toString()) - 1).to.be.equal(
                Number(afterlimit.toString()),
            );
        });

        it('Should send a token transfer without paying gas and not increases the limit', async function () {
            const address = await account.getAddress();
            const prevlimit = await ethdenverPaymaster.getRemainingUserLimit(
                address,
            );

            const tokenTransferTx =
                await mockToken.transfer.populateTransaction(
                    await richWallet.getAddress(),
                    5,
                );

            const tx = await prepareTeeTx(
                provider,
                account,
                tokenTransferTx,
                await teeValidator.getAddress(),
                keyPair,
                [],
                getGaslessPaymasterInput(ethdenverPaymaster.address),
            );

            const nonce = await getContractNonce(account);
            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );
            await txReceipt.wait();
            await waitTillNonceUpdateContract(account, nonce);

            const afterlimit = await ethdenverPaymaster.getRemainingUserLimit(
                address,
            );

            expect(prevlimit.toString()).to.be.equal(afterlimit.toString());
        });
    });
});
