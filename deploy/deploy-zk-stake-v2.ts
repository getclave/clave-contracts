/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import { parseUnits } from 'ethers';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Wallet } from 'zksync-ethers';

//import { contractNames } from './helpers/fully-qualified-contract-names';

export default async function (hre: HardhatRuntimeEnvironment): Promise<void> {
    //eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey);
    const deployer = new Deployer(hre, wallet);
    //const chainId = hre.network.config.chainId;

    const zkStakeArtifact = await deployer.loadArtifact('ZtaKeV2');

    const zkStake = await deployer.deploy(
        zkStakeArtifact,
        [
            parseUnits('50000', 6), // limit per user
            parseUnits('6000000', 6), // total limit
            '0x493257fd37edb34451f62edf8d2a0c418852ba4c', // stake token
            '0x5a7d6b2f92c77fad6ccabd7ee0624e64907eaf3e', // reward token
            '0x620F54e2BA127a605d559D24495F3C85B387AE5c', // registry address
        ],
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
}
