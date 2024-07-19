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

const syncRouter = '0x9b5def958d0f3b6955cbea4d5b7809b2fb26b059';
const syncStaking = '0x6fEbba4a360F43B71560519bCD90B3F45c8F441E';
const wethAddress = '0x5aea5775959fbc2557cc8789bc1bf90a239d9a91';

export default async function (
    hre: HardhatRuntimeEnvironment,
    releaseType?: ReleaseType,
): Promise<string> {
    //eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey);
    const deployer = new Deployer(hre, wallet);
    const chainId = hre.network.config.chainId;

    const syncEarnArtifact = await deployer.loadArtifact('SyncEarnRouterV2');

    const syncEarn = await deployer.deploy(
        syncEarnArtifact,
        [syncRouter, syncStaking, wethAddress],
        undefined,
        [],
    );

    const syncEarnAddress = await syncEarn.getAddress();

    console.log(`SyncEarnRouterV2 address: ${syncEarnAddress}`);

    if (chainId === 0x12c || chainId === 0x144) {
        try {
            const verificationId = await hre.run('verify:verify', {
                address: syncEarnAddress,
                contract: contractNames.syncEarnRouterV2,
                constructorArguments: [syncRouter, syncStaking, wethAddress],
            });
            console.log(`Verification ID: ${verificationId}`);
        } catch (e) {
            console.log(e);
        }
    }

    // if (releaseType != null) {
    //     const key: AddressKey = 'SYNC_EARN_ROUTER';
    //     updateAddress(releaseType, key, syncEarnAddress);
    // }

    return syncEarnAddress;
}
