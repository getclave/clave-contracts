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

    const zkStakeArtifact = await deployer.loadArtifact('ZtaKe');

    const zkStake = await deployer.deploy(
        zkStakeArtifact,
        ['50000000000000000000000', '6000000000000000000000000'],
        undefined,
        [],
    );

    const zkStakeAddress = await zkStake.getAddress();

    console.log(`ZtaKe address: ${zkStakeAddress}`);

    // if (chainId === 0x12c || chainId === 0x144) {
    //     try {
    //         const verificationId = await hre.run('verify:verify', {
    //             address: zkStakeAddress,
    //             contract: contractNames.ZtaKe,
    //             constructorArguments: [1000000, 10000000],
    //         });
    //         console.log(`Verification ID: ${verificationId}`);
    //     } catch (e) {
    //         console.log(e);
    //     }
    // }

    // if (releaseType != null) {
    //     const key: AddressKey = 'SYNC_EARN_ROUTER';
    //     updateAddress(releaseType, key, syncEarnAddress);
    // }

    return zkStakeAddress;
}
