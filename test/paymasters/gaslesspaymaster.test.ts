/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { assert, expect } from 'chai';
import { parseEther } from 'ethers';
import * as hre from 'hardhat';
import type { Contract, Wallet } from 'zksync-ethers';
import { Provider, utils } from 'zksync-ethers';

import { LOCAL_RICH_WALLETS, getWallet } from '../../deploy/utils';
import type { CallStruct } from '../../typechain-types/contracts/batch/BatchCaller';
import { ClaveDeployer } from '../utils/deployer';
import { fixture } from '../utils/fixture';
import { PAYMASTERS } from '../utils/names';
import { getGaslessPaymasterInput } from '../utils/paymasters';
import {
    ethTransfer,
    prepareMockBatchTx,
    prepareMockTx,
} from '../utils/transactions';

describe('Clave Contracts - Paymaster tests', () => {
    let deployer: ClaveDeployer;
    let provider: Provider;
    let richWallet: Wallet;
    let batchCaller: Contract;
    let registry: Contract;
    let mockValidator: Contract;
    let account: Contract;

    let gaslessPaymaster: Contract;
    let erc20: Contract;

    before(async () => {
        richWallet = getWallet(hre, LOCAL_RICH_WALLETS[0].privateKey);
        deployer = new ClaveDeployer(hre, richWallet);
        provider = new Provider(hre.network.config.url, undefined, {
            cacheTimeout: -1,
        });

        [batchCaller, registry, , , mockValidator, account] = await fixture(
            deployer,
        );

        const accountAddress = await account.getAddress();

        await deployer.fund(10000, accountAddress);

        erc20 = await deployer.deployCustomContract('MockStable', []);
        await erc20.mint(accountAddress, parseEther('100000'));

        gaslessPaymaster = await deployer.paymaster(PAYMASTERS.GASLESS, {
            gasless: [await registry.getAddress(), 3],
        });

        await deployer.fund(50, await gaslessPaymaster.getAddress());
    });

    it('Should fund the paymaster and account', async () => {
        expect(
            await provider.getBalance(await gaslessPaymaster.getAddress()),
        ).to.eq(parseEther('50'));

        expect(await provider.getBalance(await account.getAddress())).to.eq(
            parseEther('10000'),
        );

        expect(await erc20.balanceOf(await account.getAddress())).to.be.eq(
            parseEther('100000'),
        );
    });

    describe('Gasless Paymaster', () => {
        let accountAddress: string;
        let richAddress: string;
        let paymasterAddress: string;

        let accountBalanceBefore: bigint;
        let richBalanceBefore: bigint;
        let paymasterBalanceBefore: bigint;

        let paymasterUserLimit: bigint;

        before(async () => {
            const addresses = await Promise.all([
                account.getAddress(),
                richWallet.getAddress(),
                gaslessPaymaster.getAddress(),
            ]);
            [accountAddress, richAddress, paymasterAddress] = addresses;
        });

        beforeEach(async () => {
            const balances = await Promise.all([
                provider.getBalance(accountAddress),
                provider.getBalance(richAddress),
                provider.getBalance(paymasterAddress),
            ]);
            [accountBalanceBefore, richBalanceBefore, paymasterBalanceBefore] =
                balances;

            paymasterUserLimit = await gaslessPaymaster.getRemainingUserLimit(
                accountAddress,
            );
        });

        it('should send ETH and do not pay gas', async () => {
            const amount = parseEther('1');

            const txData = ethTransfer(richAddress, amount);
            const tx = await prepareMockTx(
                provider,
                account,
                txData,
                await mockValidator.getAddress(),
                getGaslessPaymasterInput(paymasterAddress),
            );
            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );
            await txReceipt.wait();

            const [accountBalanceAfter, richBalanceAfter] = await Promise.all([
                provider.getBalance(accountAddress),
                provider.getBalance(richAddress),
            ]);

            expect(accountBalanceAfter).to.be.eq(accountBalanceBefore - amount);
            expect(richBalanceAfter).to.be.equal(richBalanceBefore + amount);

            // Gas payment check
            const gaslessPaymasterBalanceAfter = await provider.getBalance(
                await gaslessPaymaster.getAddress(),
            );

            expect(gaslessPaymasterBalanceAfter).is.lessThan(
                paymasterBalanceBefore,
            );

            const newPaymasterUserLimit: bigint =
                await gaslessPaymaster.getRemainingUserLimit(accountAddress);
            expect(paymasterUserLimit).to.be.eq(
                newPaymasterUserLimit + BigInt(1),
            );
        });

        it('should send ERC20 token / contract interaction and do not pay gas', async () => {
            const amount = parseEther('100');

            const [accountERC20BalanceBefore, richERC20BalanceBefore] =
                await Promise.all([
                    erc20.balanceOf(accountAddress),
                    erc20.balanceOf(richAddress),
                ]);

            const txData = {
                to: await erc20.getAddress(),
                value: 0,
                data: erc20.interface.encodeFunctionData('transfer', [
                    richAddress,
                    amount,
                ]),
            };
            const tx = await prepareMockTx(
                provider,
                account,
                txData,
                await mockValidator.getAddress(),
                getGaslessPaymasterInput(paymasterAddress),
            );

            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );
            await txReceipt.wait();

            const [accountERC20BalanceAfter, richERC20BalanceAfter] =
                await Promise.all([
                    erc20.balanceOf(accountAddress),
                    erc20.balanceOf(richAddress),
                ]);

            expect(accountERC20BalanceAfter).to.be.equal(
                accountERC20BalanceBefore - amount,
            );
            expect(richERC20BalanceAfter).to.be.equal(
                richERC20BalanceBefore + amount,
            );

            // Gas payment check
            const accountBalanceAfter = await provider.getBalance(
                accountAddress,
            );
            expect(accountBalanceBefore).to.be.eq(accountBalanceAfter);

            const gaslessPaymasterBalanceAfter = await provider.getBalance(
                await gaslessPaymaster.getAddress(),
            );

            expect(gaslessPaymasterBalanceAfter).is.lessThan(
                paymasterBalanceBefore,
            );

            const newPaymasterUserLimit: bigint =
                await gaslessPaymaster.getRemainingUserLimit(accountAddress);
            expect(paymasterUserLimit).to.be.eq(
                newPaymasterUserLimit + BigInt(1),
            );
        });

        it('should send batch tx / delegate call and do not pay gas', async () => {
            const amount = parseEther('100');

            const [accountERC20BalanceBefore, richERC20BalanceBefore] =
                await Promise.all([
                    erc20.balanceOf(accountAddress),
                    erc20.balanceOf(richAddress),
                ]);

            const calls: Array<CallStruct> = [
                {
                    target: richAddress,
                    allowFailure: false,
                    value: amount,
                    callData: '0x',
                },
                {
                    target: await erc20.getAddress(),
                    allowFailure: false,
                    value: 0,
                    callData: erc20.interface.encodeFunctionData('transfer', [
                        richAddress,
                        amount,
                    ]),
                },
            ];

            const batchTx = await prepareMockBatchTx(
                provider,
                account,
                await batchCaller.getAddress(),
                calls,
                await mockValidator.getAddress(),
                [],
                getGaslessPaymasterInput(paymasterAddress),
            );

            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(batchTx),
            );
            await txReceipt.wait();

            const [accountBalanceAfter, richBalanceAfter] = await Promise.all([
                provider.getBalance(accountAddress),
                provider.getBalance(richAddress),
            ]);

            expect(accountBalanceAfter).to.be.eq(accountBalanceBefore - amount);
            expect(richBalanceAfter).to.be.equal(richBalanceBefore + amount);

            const [accountERC20BalanceAfter, richERC20BalanceAfter] =
                await Promise.all([
                    erc20.balanceOf(accountAddress),
                    erc20.balanceOf(richAddress),
                ]);

            expect(accountERC20BalanceAfter).to.be.equal(
                accountERC20BalanceBefore - amount,
            );
            expect(richERC20BalanceAfter).to.be.equal(
                richERC20BalanceBefore + amount,
            );

            // Gas payment check
            const gaslessPaymasterBalanceAfter = await provider.getBalance(
                await gaslessPaymaster.getAddress(),
            );

            expect(gaslessPaymasterBalanceAfter).is.lessThan(
                paymasterBalanceBefore,
            );

            const newPaymasterUserLimit: bigint =
                await gaslessPaymaster.getRemainingUserLimit(accountAddress);
            expect(paymasterUserLimit).to.be.eq(
                newPaymasterUserLimit + BigInt(1),
            );
        });

        it('should revert if userLimit is reached', async () => {
            expect(paymasterUserLimit).to.be.eq(BigInt(0));

            const amount = parseEther('1');

            const txData = ethTransfer(richAddress, amount);
            const tx = await prepareMockTx(
                provider,
                account,
                txData,
                await mockValidator.getAddress(),
                getGaslessPaymasterInput(paymasterAddress),
            );

            try {
                await provider.broadcastTransaction(utils.serializeEip712(tx));
                assert(false, 'Should revert');
            } catch (error) {}

            const accountBalanceAfter = await provider.getBalance(
                accountAddress,
            );
            expect(accountBalanceAfter).to.be.eq(accountBalanceBefore);
        });

        it('should be able to increase user limit', async () => {
            const newUserLimit = 4;
            const tx = await gaslessPaymaster.updateUserLimit(newUserLimit);
            await tx.wait();

            const updatedUserLimit = await gaslessPaymaster.userLimit();
            expect(updatedUserLimit).to.be.eq(newUserLimit);
        });

        it('should send ETH and do not pay gas after increasing the user limit', async () => {
            const amount = parseEther('1');

            const txData = ethTransfer(richAddress, amount);
            const tx = await prepareMockTx(
                provider,
                account,
                txData,
                await mockValidator.getAddress(),
                getGaslessPaymasterInput(paymasterAddress),
            );
            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );
            await txReceipt.wait();

            const [accountBalanceAfter, richBalanceAfter] = await Promise.all([
                provider.getBalance(accountAddress),
                provider.getBalance(richAddress),
            ]);

            expect(accountBalanceAfter).to.be.eq(accountBalanceBefore - amount);
            expect(richBalanceAfter).to.be.equal(richBalanceBefore + amount);

            // Gas payment check
            const gaslessPaymasterBalanceAfter = await provider.getBalance(
                await gaslessPaymaster.getAddress(),
            );

            expect(gaslessPaymasterBalanceAfter).is.lessThan(
                paymasterBalanceBefore,
            );

            const newPaymasterUserLimit: bigint =
                await gaslessPaymaster.getRemainingUserLimit(accountAddress);
            expect(paymasterUserLimit).to.be.eq(
                newPaymasterUserLimit + BigInt(1),
            );
        });

        it('should be able to add limitless addresses', async () => {
            const tx = await gaslessPaymaster.addLimitlessAddresses([
                accountAddress,
            ]);
            await tx.wait();

            expect(await gaslessPaymaster.limitlessAddresses(accountAddress)).to
                .be.true;
        });

        it('should send ETH and do not pay gas after being limitless address', async () => {
            expect(paymasterUserLimit).to.be.eq(BigInt(0));

            const amount = parseEther('1');

            const txData = ethTransfer(richAddress, amount);
            const tx = await prepareMockTx(
                provider,
                account,
                txData,
                await mockValidator.getAddress(),
                getGaslessPaymasterInput(paymasterAddress),
            );
            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );
            await txReceipt.wait();

            const [accountBalanceAfter, richBalanceAfter] = await Promise.all([
                provider.getBalance(accountAddress),
                provider.getBalance(richAddress),
            ]);

            expect(accountBalanceAfter).to.be.eq(accountBalanceBefore - amount);
            expect(richBalanceAfter).to.be.equal(richBalanceBefore + amount);

            // Gas payment check
            const gaslessPaymasterBalanceAfter = await provider.getBalance(
                await gaslessPaymaster.getAddress(),
            );

            expect(gaslessPaymasterBalanceAfter).is.lessThan(
                paymasterBalanceBefore,
            );
        });
    });
});
