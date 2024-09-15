/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { expect } from 'chai';
import { parseEther } from 'ethers';
import * as hre from 'hardhat';
import type { Contract, Wallet } from 'zksync-ethers';
import { Provider, utils } from 'zksync-ethers';

import { LOCAL_RICH_WALLETS, getWallet } from '../../deploy/utils';
import type { CallStruct } from '../../typechain-types/contracts/batch/BatchCaller';
import { ClaveDeployer } from '../utils/deployer';
import { fixture } from '../utils/fixture';
import {
    ethTransfer,
    prepareMockBatchTx,
    prepareMockTx,
} from '../utils/transactions';

describe('Clave Contracts - Account tests', () => {
    let deployer: ClaveDeployer;
    let provider: Provider;
    let richWallet: Wallet;
    let batchCaller: Contract;
    let mockValidator: Contract;
    let account: Contract;

    let erc20: Contract;

    before(async () => {
        richWallet = getWallet(hre, LOCAL_RICH_WALLETS[0].privateKey);
        deployer = new ClaveDeployer(hre, richWallet);
        provider = new Provider(hre.network.config.url, undefined, {
            cacheTimeout: -1,
        });

        [batchCaller, , , , mockValidator, account] = await fixture(deployer);

        const accountAddress = await account.getAddress();

        await deployer.fund(10000, accountAddress);

        erc20 = await deployer.deployCustomContract('MockStable', []);
        await erc20.mint(accountAddress, parseEther('100000'));
    });

    describe('Transactions', () => {
        let accountAddress: string;
        let richAddress: string;
        let accountBalanceBefore: bigint;
        let richBalanceBefore: bigint;

        before(async () => {
            const addresses = await Promise.all([
                account.getAddress(),
                richWallet.getAddress(),
            ]);
            [accountAddress, richAddress] = addresses;
        });

        beforeEach(async () => {
            const balances = await Promise.all([
                provider.getBalance(accountAddress),
                provider.getBalance(richAddress),
            ]);
            [accountBalanceBefore, richBalanceBefore] = balances;
        });

        it('should send ETH', async () => {
            const amount = parseEther('1');
            const delta = parseEther('0.01');

            const txData = ethTransfer(richAddress, amount);
            const tx = await prepareMockTx(
                provider,
                account,
                txData,
                await mockValidator.getAddress(),
            );
            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );
            await txReceipt.wait();

            const [accountBalanceAfter, richBalanceAfter] = await Promise.all([
                provider.getBalance(accountAddress),
                provider.getBalance(richAddress),
            ]);

            expect(accountBalanceAfter).to.be.closeTo(
                accountBalanceBefore - amount,
                delta,
            );
            expect(richBalanceAfter).to.be.equal(richBalanceBefore + amount);
        });

        it('should send ERC20 token / contract interaction and pay gas', async () => {
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
            expect(accountBalanceBefore).to.be.greaterThan(accountBalanceAfter);
        });

        it('should send batch tx / delegate call', async () => {
            const amount = parseEther('100');
            const delta = parseEther('0.01');

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
            );

            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(batchTx),
            );
            await txReceipt.wait();

            const [accountBalanceAfter, richBalanceAfter] = await Promise.all([
                provider.getBalance(accountAddress),
                provider.getBalance(richAddress),
            ]);

            expect(accountBalanceAfter).to.be.closeTo(
                accountBalanceBefore - amount,
                delta,
            );
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
        });
    });
});
