/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { AddressKey } from '@getclave/constants';
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Wallet } from 'zksync-web3';

import { contractNames } from './helpers/fully-qualified-contract-names';
import type { ReleaseType } from './helpers/release';
import { updateAddress } from './helpers/release';

export default async function (
    hre: HardhatRuntimeEnvironment,
    releaseType?: ReleaseType,
): Promise<string> {
    //eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey);
    const deployer = new Deployer(hre, wallet);
    const chainId = await deployer.zkWallet.getChainId();

    const batchCallerArtifact = await deployer.loadArtifact('BatchCaller');

    const batchCaller = await deployer.deploy(
        batchCallerArtifact,
        [],
        undefined,
        [],
    );

    console.log(`BatchCaller address: ${batchCaller.address}`);

    if (chainId === 0x118) {
        try {
            const verificationId = await hre.run('verify:verify', {
                address: batchCaller.address,
                contract: contractNames.batchCaller,
                constructorArguments: [],
            });
            console.log(`Verification ID: ${verificationId}`);
        } catch (e) {
            console.log(e);
        }
    }

    if (releaseType != null) {
        const key: AddressKey = 'BATCH_CALLER';
        updateAddress(releaseType, key, batchCaller.address);
    }

    return batchCaller.address;
}
