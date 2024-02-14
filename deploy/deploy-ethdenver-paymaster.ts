/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
// import { type AddressKey } from '@getclave/constants';
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import { parseEther } from 'ethers';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Provider, Wallet } from 'zksync-ethers';

import { contractNames } from './helpers/fully-qualified-contract-names';
import type { ReleaseType } from './helpers/release';
import {
    loadAddress,
    /**updateAddress*/
} from './helpers/release';

const TX_LIMIT = 30;
const ETHDENVER_TOKEN = '0x';
const FUND = parseEther('0.1');

export default async function (
    hre: HardhatRuntimeEnvironment,
    releaseType?: ReleaseType,
    registryAddress?: string,
): Promise<void> {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const provider = new Provider(hre.network.config.url);
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey).connect(provider);
    const deployer = new Deployer(hre, wallet);
    const chainId = hre.network.config.chainId;

    const ethdenverPaymasterArtifact = await deployer.loadArtifact(
        'ETHDenverPaymaster',
    );

    const REGISTRY_ADDRESS =
        registryAddress || (await loadAddress(releaseType, 'REGISTRY'));

    console.log(
        `Used registry address ${REGISTRY_ADDRESS} to deploy ethdenver paymaster`,
    );

    const ethdenverPaymaster = await deployer.deploy(
        ethdenverPaymasterArtifact,
        [REGISTRY_ADDRESS, TX_LIMIT, ETHDENVER_TOKEN],
        undefined,
        [],
    );

    const ethdenverPaymasterAddress = await ethdenverPaymaster.getAddress();

    console.log(
        `ETHDenverPaymaster deployment address: ${ethdenverPaymasterAddress}`,
    );

    if (chainId === 0x12c) {
        try {
            const verificationId = await hre.run('verify:verify', {
                address: ethdenverPaymasterAddress,
                contract: contractNames.ethdenverPaymaster,
                constructorArguments: [
                    REGISTRY_ADDRESS,
                    TX_LIMIT,
                    ETHDENVER_TOKEN,
                ],
            });

            console.log(
                `Verification ID - ETHDenverPaymsater: ${verificationId}`,
            );
        } catch (error) {
            console.log(
                "Couldn't verify the ${contractNames.ethdenverPaymaster} contracts:",
                error,
            );
        }
    }

    // if (releaseType != null) {
    //     const key: AddressKey = 'GASLESS_PAYMASTER';
    //     updateAddress(releaseType, key, ethdenverPaymasterAddress);
    // }

    if (FUND > 0) {
        await wallet.sendTransaction({
            to: ethdenverPaymasterAddress,
            value: FUND,
        });
    }
}
