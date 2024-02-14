/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { type AddressKey } from '@getclave/constants';
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Provider, Wallet } from 'zksync-ethers';

import { contractNames } from './helpers/fully-qualified-contract-names';
import type { ReleaseType } from './helpers/release';
import { loadAddress, updateAddress } from './helpers/release';

const TX_LIMIT = 20;
const MINTER_ADDRESS = '';

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
        'BUIDLBucks',
    );

    const REGISTRY_ADDRESS =
        registryAddress || (await loadAddress(releaseType, 'REGISTRY'));

    console.log(
        `Used registry address ${REGISTRY_ADDRESS} to deploy gasless paymaster`,
    );

    const ethdenverPaymaster = await deployer.deploy(
        ethdenverPaymasterArtifact,
        [REGISTRY_ADDRESS, TX_LIMIT, MINTER_ADDRESS],
        undefined,
        [],
    );

    const ethdenverPaymasterAddress = await ethdenverPaymaster.getAddress();

    console.log(
        `ETHDenverPaymaster deployment address: ${ethdenverPaymasterAddress}`,
    );

    if (chainId === 0x12c) {
        try {
            const verificationIdGasless = await hre.run('verify:verify', {
                address: ethdenverPaymasterAddress,
                contract: contractNames.ethdenverPaymaster,
                constructorArguments: [
                    REGISTRY_ADDRESS,
                    TX_LIMIT,
                    MINTER_ADDRESS,
                ],
            });

            console.log(
                `Verification ID - ETHDenverPaymaster: ${verificationIdGasless}`,
            );
        } catch (error) {
            console.log(
                "Couldn't verify the ${contractNames.ethdenverPaymaster} contracts:",
                error,
            );
        }
    }

    if (releaseType != null) {
        const key: AddressKey = 'GASLESS_PAYMASTER';
        updateAddress(releaseType, key, ethdenverPaymasterAddress);
    }
}
