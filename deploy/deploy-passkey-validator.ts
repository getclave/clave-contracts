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

    const passkeyValidatorArtifact = await deployer.loadArtifact(
        'PasskeyValidatorConstant',
    );

    const passkeyValidator = await deployer.deploy(
        passkeyValidatorArtifact,
        [],
        undefined,
        [],
    );

    const passkeyValidatorAddress = await passkeyValidator.getAddress();

    console.log(`Passkey Validator address: ${passkeyValidatorAddress}`);

    if (chainId === 0x12c || chainId === 0x144) {
        const verificationId = await hre.run('verify:verify', {
            address: passkeyValidatorAddress,
            contract: contractNames.passkeyValidator,
            constructorArguments: [],
        });

        console.log(`Verification ID: ${verificationId}`);
    }

    if (releaseType != null) {
        const key: AddressKey = 'VALIDATOR_ADDRESS';
        updateAddress(releaseType, key, passkeyValidatorAddress);
    }

    return passkeyValidatorAddress;
}
