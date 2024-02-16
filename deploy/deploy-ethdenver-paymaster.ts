/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Provider, Wallet } from 'zksync-ethers';

import { contractNames } from './helpers/fully-qualified-contract-names';
import type { ReleaseType } from './helpers/release';
import { loadAddress } from './helpers/release';

const TX_LIMIT = 5;

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
        [REGISTRY_ADDRESS, TX_LIMIT],
        undefined,
        [],
    );

    const ethdenverPaymasterAddress = await ethdenverPaymaster.getAddress();

    console.log(
        `ETHDenverPaymaster deployment address: ${ethdenverPaymasterAddress}`,
    );

    if (chainId === 0x12c || chainId === 0x144) {
        try {
            const verificationIdETHDenver = await hre.run('verify:verify', {
                address: ethdenverPaymasterAddress,
                contract: contractNames.ethdenverPaymaster,
                constructorArguments: [REGISTRY_ADDRESS, TX_LIMIT],
            });

            console.log(
                `Verification ID - ETHDenverPaymaster: ${verificationIdETHDenver}`,
            );
        } catch (error) {
            console.log(
                "Couldn't verify the ${contractNames.ethdenverPaymaster} contracts:",
                error,
            );
        }
    }
}
