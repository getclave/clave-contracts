/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Wallet } from 'zksync-ethers';

//import { contractNames } from './helpers/fully-qualified-contract-names';

export default async function (hre: HardhatRuntimeEnvironment): Promise<void> {
    //eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey);
    const deployer = new Deployer(hre, wallet);
    //const chainId = hre.network.config.chainId;

    const routerArtifact = await deployer.loadArtifact('ClaveStakingRouter');

    const router = await deployer.deploy(
        routerArtifact,
        [
            '0x44393C30e36C9Cba3E614E502708B64402bA22a2', // staking address
        ],
        undefined,
        [],
    );

    const routerAddress = await router.getAddress();

    console.log(`router address: ${routerAddress}`);

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
