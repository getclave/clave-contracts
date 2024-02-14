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
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey);
    const deployer = new Deployer(hre, wallet);
    const chainId = hre.network.config.chainId;

    const tokenArtifact = await deployer.loadArtifact('BUIDLToken');

    const token = await deployer.deploy(tokenArtifact, [], undefined, []);

    const tokenAddress = await token.getAddress();

    console.log(`Clave BUIDL Token address: ${token.address}`);

    if (chainId === 0x12c || chainId === 0x144) {
        try {
            const verificationId = await hre.run('verify:verify', {
                address: tokenAddress,
                contract: contractNames.buidlToken,
                constructorArguments: undefined,
            });
            console.log(`Verification ID: ${verificationId}`);
        } catch (e) {
            console.log(e);
        }
    }

    return tokenAddress;
}
