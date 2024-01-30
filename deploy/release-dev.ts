/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { HardhatRuntimeEnvironment } from 'hardhat/types';

import deployBatchCaller from './deploy-batch-caller';
import deployCloudRecovery from './deploy-cloud-recovery';
import deployFactory from './deploy-factory';
import deployImplementation from './deploy-implementation';
import deployPasskeyValidator from './deploy-passkey-validator';
import deployPaymaster from './deploy-paymaster';
import deployRegistry from './deploy-registry';
import deploySocialRecovery from './deploy-social-recovery';
import { ReleaseType } from './helpers/release';

export default async function (hre: HardhatRuntimeEnvironment): Promise<void> {
    console.log(`Taking a development release on ${hre.network.name}`);
    const batchCaller = await deployBatchCaller(hre, ReleaseType.development);
    const implementation = await deployImplementation(
        hre,
        ReleaseType.development,
        batchCaller,
    );
    const registry = await deployRegistry(hre, ReleaseType.development);
    await deployFactory(hre, ReleaseType.development, implementation, registry);
    await deployPasskeyValidator(hre, ReleaseType.development);
    await deploySocialRecovery(hre, ReleaseType.development);
    await deployCloudRecovery(hre, ReleaseType.development);
    await deployPaymaster(hre, ReleaseType.development, registry);
}
