/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { AddressKey } from '@getclave/constants';
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Wallet } from 'zksync-ethers';

import { contractNames } from './helpers/fully-qualified-contract-names';
import type { ReleaseType } from './helpers/release';
import { updateAddress } from './helpers/release';

const KoiRouter = '0x8b791913eb07c32779a16750e3868aa8495f5964';

export default async function (
    hre: HardhatRuntimeEnvironment,
    releaseType?: ReleaseType,
): Promise<string> {
    //eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey);
    const deployer = new Deployer(hre, wallet);
    const chainId = hre.network.config.chainId;

    const koiEarnArtifact = await deployer.loadArtifact('KoiEarnRouter');

    const koiEarn = await deployer.deploy(
        koiEarnArtifact,
        [KoiRouter],
        undefined,
        [],
    );

    const koiEarnAddress = await koiEarn.getAddress();

    console.log(`KoiEarnRouter address: ${koiEarnAddress}`);

    if (chainId === 0x12c || chainId === 0x144) {
        try {
            const verificationId = await hre.run('verify:verify', {
                address: koiEarnAddress,
                contract: contractNames.koiEarnRouter,
                constructorArguments: [KoiRouter],
            });
            console.log(`Verification ID: ${verificationId}`);
        } catch (e) {
            console.log(e);
        }
    }

    // if (releaseType != null) {
    //     const key: AddressKey = 'KOI_EARN_ROUTER';
    //     updateAddress(releaseType, key, koiEarnAddress);
    // }

    return koiEarnAddress;
}
