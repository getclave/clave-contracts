/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Wallet } from 'zksync-ethers';

import { contractNames } from './helpers/fully-qualified-contract-names';
import type { ReleaseType } from './helpers/release';

export default async function (
    hre: HardhatRuntimeEnvironment,
    releaseType?: ReleaseType,
): Promise<string> {
    //eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey);
    const deployer = new Deployer(hre, wallet);
    const chainId = hre.network.config.chainId;
    const SMOOTHIE_LIMIT = 3;

    const smoothieStore = await deployer.loadArtifact('SmoothieStore');

    const SmoothieStore = await deployer.deploy(
        smoothieStore,
        [SMOOTHIE_LIMIT],
        undefined,
        [],
    );

    const smoothieStoreAddress = await SmoothieStore.getAddress();

    console.log(`SmoothieStore address: ${smoothieStoreAddress}`);

    if (chainId === 0x12c || chainId === 0x144) {
        try {
            const verificationId = await hre.run('verify:verify', {
                address: smoothieStoreAddress,
                contract: contractNames.smoothieStore,
                constructorArguments: [SMOOTHIE_LIMIT],
            });
            console.log(`Verification ID: ${verificationId}`);
        } catch (e) {
            console.log(e);
        }
    }

    return smoothieStoreAddress;
}
