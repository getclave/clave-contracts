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
import { PAYMASTERS } from '../utils/names';
import { getERC20PaymasterInput, getOraclePayload } from '../utils/paymasters';
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
    let mockValidator: Contract;
    let account: Contract;

    let erc20Paymaster: Contract;
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

        erc20Paymaster = await deployer.paymaster(PAYMASTERS.ERC20_MOCK, {
            erc20: [
                {
                    tokenAddress: await erc20.getAddress(),
                    decimals: 18,
                    priceMarkup: 20000,
                },
            ],
        });

        await deployer.fund(50, await erc20Paymaster.getAddress());
    });

    it('Should fund the paymaster and account', async () => {
        expect(
            await provider.getBalance(await erc20Paymaster.getAddress()),
        ).to.eq(parseEther('50'));

        expect(await provider.getBalance(await account.getAddress())).to.eq(
            parseEther('10000'),
        );

        expect(await erc20.balanceOf(await account.getAddress())).to.be.eq(
            parseEther('100000'),
        );
    });

    describe('ERC20 Paymaster (Mocked Oracle)', () => {
        let accountAddress: string;
        let richAddress: string;
        let paymasterAddress: string;

        let accountBalanceBefore: bigint;
        let richBalanceBefore: bigint;
        let paymasterBalanceBefore: bigint;
        let accountERC20BalanceBefore: bigint;
        let paymasterERC20BalanceBefore: bigint;

        before(async () => {
            const addresses = await Promise.all([
                account.getAddress(),
                richWallet.getAddress(),
                erc20Paymaster.getAddress(),
            ]);
            [accountAddress, richAddress, paymasterAddress] = addresses;
        });

        beforeEach(async () => {
            const balances = await Promise.all([
                provider.getBalance(accountAddress),
                provider.getBalance(richAddress),
                provider.getBalance(paymasterAddress),
                erc20.balanceOf(accountAddress),
                erc20.balanceOf(paymasterAddress),
            ]);
            [
                accountBalanceBefore,
                richBalanceBefore,
                paymasterBalanceBefore,
                accountERC20BalanceBefore,
                paymasterERC20BalanceBefore,
            ] = balances;
        });

        it('should send ETH and pay gas with erc20 token', async () => {
            const amount = parseEther('1');

            const txData = ethTransfer(richAddress, amount);
            const tx = await prepareMockTx(
                provider,
                account,
                txData,
                await mockValidator.getAddress(),
                getERC20PaymasterInput(
                    paymasterAddress,
                    await erc20.getAddress(),
                    parseEther('50'),
                    await getOraclePayload(erc20Paymaster),
                ),
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
                await erc20Paymaster.getAddress(),
            );

            expect(gaslessPaymasterBalanceAfter).is.lessThan(
                paymasterBalanceBefore,
            );

            const [accountERC20BalanceAfter, paymasterERC20BalanceAfter] =
                await Promise.all([
                    erc20.balanceOf(accountAddress),
                    erc20.balanceOf(paymasterAddress),
                ]);

            expect(
                accountERC20BalanceBefore + paymasterERC20BalanceBefore,
            ).to.be.equal(
                accountERC20BalanceAfter + paymasterERC20BalanceAfter,
            );
        });

        it('should send ERC20 token / contract interaction and pay gas with erc20 token', async () => {
            const amount = parseEther('100');

            const richERC20BalanceBefore = await erc20.balanceOf(richAddress);

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
                getERC20PaymasterInput(
                    paymasterAddress,
                    await erc20.getAddress(),
                    parseEther('50'),
                    await getOraclePayload(erc20Paymaster),
                ),
            );

            const txReceipt = await provider.broadcastTransaction(
                utils.serializeEip712(tx),
            );
            await txReceipt.wait();

            const richERC20BalanceAfter = await erc20.balanceOf(richAddress);

            expect(richERC20BalanceAfter).to.be.equal(
                richERC20BalanceBefore + amount,
            );

            // Gas payment check
            const accountBalanceAfter = await provider.getBalance(
                accountAddress,
            );
            expect(accountBalanceBefore).to.be.eq(accountBalanceAfter);

            const gaslessPaymasterBalanceAfter = await provider.getBalance(
                await erc20Paymaster.getAddress(),
            );
            expect(gaslessPaymasterBalanceAfter).is.lessThan(
                paymasterBalanceBefore,
            );
        });

        it('should send batch tx / delegate call and pay gas with erc20 token', async () => {
            const amount = parseEther('100');

            const richERC20BalanceBefore = await erc20.balanceOf(richAddress);

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
                getERC20PaymasterInput(
                    paymasterAddress,
                    await erc20.getAddress(),
                    parseEther('50'),
                    await getOraclePayload(erc20Paymaster),
                ),
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

            const richERC20BalanceAfter = await erc20.balanceOf(richAddress);

            expect(richERC20BalanceAfter).to.be.equal(
                richERC20BalanceBefore + amount,
            );

            // Gas payment check
            const gaslessPaymasterBalanceAfter = await provider.getBalance(
                await erc20Paymaster.getAddress(),
            );

            expect(gaslessPaymasterBalanceAfter).is.lessThan(
                paymasterBalanceBefore,
            );
        });
    });
});
