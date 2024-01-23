/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Wallet } from 'zksync-ethers';

export default async function (
    hre: HardhatRuntimeEnvironment,
): Promise<string> {
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey);
    const deployer = new Deployer(hre, wallet);

    const verifierArtifact = await deployer.loadArtifact('P256VERIFY');

    const verifier = await deployer.deploy(verifierArtifact, [], undefined, []);

    const verifierAddress = await verifier.getAddress();

    console.log(`verifier address: ${verifierAddress}`);

    return verifierAddress;
}
