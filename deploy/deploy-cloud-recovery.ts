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
import { ReleaseType, updateAddress } from './helpers/release';

export default async function (
    hre: HardhatRuntimeEnvironment,
    releaseType?: ReleaseType,
): Promise<string> {
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey);
    const deployer = new Deployer(hre, wallet);
    const chainId = await deployer.zkWallet.getChainId();

    const CRMArtifact = await deployer.loadArtifact('CloudRecoveryModule');

    const timelock = releaseType === ReleaseType.production ? 172_800 : 120;

    const CRM = await deployer.deploy(
        CRMArtifact,
        ['crm', '1', timelock],
        undefined,
        [],
    );

    console.log(`Cloud Recovery address: ${CRM.address}`);

    if (chainId === 0x118) {
        try {
            const verificationId = await hre.run('verify:verify', {
                address: CRM.address,
                contract: contractNames.cloudRecovery,
                constructorArguments: ['crm', '1', timelock],
            });
            console.log(`Verification ID: ${verificationId}`);
        } catch (e) {
            console.log(e);
        }
    }

    if (releaseType != null) {
        const key: AddressKey = 'CLOUD_RECOVERY';
        updateAddress(releaseType, key, CRM.address);
    }

    return CRM.address;
}
