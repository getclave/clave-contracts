/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { type AddressKey } from '@getclave/constants';
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Provider, Wallet } from 'zksync-web3';

import { contractNames } from './helpers/fully-qualified-contract-names';
import { paymasterData } from './helpers/paymaster-data';
import type { ReleaseType } from './helpers/release';
import { loadAddress, updateAddress } from './helpers/release';

export default async function (
    hre: HardhatRuntimeEnvironment,
    releaseType?: ReleaseType,
    registryAddress?: string,
): Promise<void> {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const provider = new Provider(hre.config.networks.zkSyncTestnet.url);
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey).connect(provider);
    const deployer = new Deployer(hre, wallet);
    const chainId = await deployer.zkWallet.getChainId();

    if (paymasterData.deploys[0]) {
        const erc20PaymasterArtifact = await deployer.loadArtifact(
            'ERC20Paymaster',
        );

        const erc20Paymaster = await deployer.deploy(
            erc20PaymasterArtifact,
            [paymasterData.tokenInput],
            undefined,
            [],
        );

        console.log(
            `ERC20Paymaster deployment address: ${erc20Paymaster.address}`,
        );

        if (chainId === 0x12c) {
            try {
                const verificationIdERC20 = await hre.run('verify:verify', {
                    address: erc20Paymaster.address,
                    contract: contractNames.erc20Paymaster,
                    constructorArguments: [paymasterData.tokenInput],
                });

                console.log(
                    `Verification ID - ERC20Paymaster: ${verificationIdERC20}`,
                );
            } catch (error) {
                console.log(
                    "Couldn't verify the ${contractNames.erc20Paymaster} contracts:",
                    error,
                );
            }
        }

        if (releaseType != null) {
            const key: AddressKey = 'ERC20_PAYMASTER';
            updateAddress(releaseType, key, erc20Paymaster.address);
        }

        if (paymasterData.fund[0].gt(0)) {
            await wallet.sendTransaction({
                to: erc20Paymaster.address,
                value: paymasterData.fund[0],
            });
        }
    }

    if (paymasterData.deploys[1]) {
        const gaslessPaymasterArtifact = await deployer.loadArtifact(
            'GaslessPaymaster',
        );

        const REGISTRY_ADDRESS =
            registryAddress || (await loadAddress(releaseType, 'REGISTRY'));

        console.log(
            `Used registry address ${REGISTRY_ADDRESS} to deploy gasless paymaster`,
        );

        const gaslessPaymaster = await deployer.deploy(
            gaslessPaymasterArtifact,
            [REGISTRY_ADDRESS, paymasterData.gaslessPaymaster_txLimit],
            undefined,
            [],
        );

        console.log(
            `GaslessPaymaster deployment address: ${gaslessPaymaster.address}`,
        );

        if (chainId === 0x12c) {
            try {
                const verificationIdGasless = await hre.run('verify:verify', {
                    address: gaslessPaymaster.address,
                    contract: contractNames.gaslessPaymaster,
                    constructorArguments: [
                        REGISTRY_ADDRESS,
                        paymasterData.gaslessPaymaster_txLimit,
                    ],
                });

                console.log(
                    `Verification ID - GaslessPaymaster: ${verificationIdGasless}`,
                );
            } catch (error) {
                console.log(
                    "Couldn't verify the ${contractNames.gaslessPaymaster} contracts:",
                    error,
                );
            }
        }

        if (releaseType != null) {
            const key: AddressKey = 'GASLESS_PAYMASTER';
            updateAddress(releaseType, key, gaslessPaymaster.address);
        }

        if (paymasterData.fund[1].gt(0)) {
            await wallet.sendTransaction({
                to: gaslessPaymaster.address,
                value: paymasterData.fund[1],
            });
        }
    }
}
