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

    const mockValidatorArtifact = await deployer.loadArtifact('MockValidator');

    const mockValidator = await deployer.deploy(
        mockValidatorArtifact,
        [],
        undefined,
        [],
    );

    const mockValidatorAddress = await mockValidator.getAddress();

    console.log(`Mock Validator address: ${mockValidatorAddress}`);

    if (chainId === 0x12c || chainId === 0x144) {
        const verificationId = await hre.run('verify:verify', {
            address: mockValidatorAddress,
            contract: contractNames.mockValidator,
            constructorArguments: [],
        });

        console.log(`Verification ID: ${verificationId}`);
    }

    return mockValidatorAddress;
}
