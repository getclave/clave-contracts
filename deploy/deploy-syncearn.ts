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
const syncStaking = '0x2b9a7d5cd64e5c1446b32e034e75a5c93b0c8bb5';
const pancakeRouter = '0xD70C70AD87aa8D45b8D59600342FB3AEe76E3c68';
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

    const syncEarnArtifact = await deployer.loadArtifact('SyncEarnRouter');

    const syncEarn = await deployer.deploy(
        syncEarnArtifact,
        [syncRouter, syncStaking, pancakeRouter, wethAddress],
        undefined,
        [],
    );

    const syncEarnAddress = await syncEarn.getAddress();

    console.log(`SyncEarnRouter address: ${syncEarnAddress}`);

    if (chainId === 0x12c || chainId === 0x144) {
        try {
            const verificationId = await hre.run('verify:verify', {
                address: syncEarnAddress,
                contract: contractNames.syncEarnRouter,
                constructorArguments: [
                    syncRouter,
                    syncStaking,
                    pancakeRouter,
                    wethAddress,
                ],
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
