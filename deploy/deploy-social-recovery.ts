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
import { type ReleaseType, updateAddress } from './helpers/release';

export default async function (
    hre: HardhatRuntimeEnvironment,
    releaseType?: ReleaseType,
): Promise<string> {
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey);
    const deployer = new Deployer(hre, wallet);
    const chainId = hre.network.config.chainId;

    const SRMArtifact = await deployer.loadArtifact('SocialRecoveryModule');

    const SRM = await deployer.deploy(
        SRMArtifact,
        ['srm', '1', 0, 0],
        undefined,
        [],
    );

    const SRMAddress = await SRM.getAddress();

    console.log(`Social Recovery address: ${SRMAddress}`);

    if (chainId === 0x12c || chainId === 0x144) {
        try {
            const verificationId = await hre.run('verify:verify', {
                address: SRMAddress,
                contract: contractNames.socialRecovery,
                constructorArguments: ['srm', '1', 0, 0],
            });
            console.log(`Verification ID: ${verificationId}`);
        } catch (e) {
            console.log(e);
        }
    }

    if (releaseType != null) {
        const key: AddressKey = 'SOCIAL_RECOVERY';
        updateAddress(releaseType, key, SRMAddress);
    }

    return SRMAddress;
}
