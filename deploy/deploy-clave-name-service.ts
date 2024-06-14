/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Wallet } from 'zksync-ethers';

import { contractNames } from './helpers/fully-qualified-contract-names';

export default async function (
    hre: HardhatRuntimeEnvironment,
): Promise<string> {
    const privateKey = process.env.PRIVATE_KEY;
    if (privateKey == undefined) throw new Error('PRIVATE_KEY not set');
    const wallet = new Wallet(privateKey);
    const deployer = new Deployer(hre, wallet);
    const chainId = hre.network.config.chainId;

    const cnsArtifact = await deployer.loadArtifact('ClaveNameService');
    const cns = await deployer.deploy(
        cnsArtifact,
        ['clave', 'eth', ''],
        undefined,
        [],
    );
    const cnsAddress = await cns.getAddress();

    console.log(`ClaveNameService address: ${cnsAddress}`);

    if (chainId === 0x12c || chainId === 0x144) {
        try {
            const verificationId = await hre.run('verify:verify', {
                address: cnsAddress,
                contract: contractNames.claveNameService,
                constructorArguments: ['clave', 'eth', ''],
            });
            console.log(`Verification ID: ${verificationId}`);
        } catch (e) {
            console.log(e);
        }
    }

    return cnsAddress;
}
