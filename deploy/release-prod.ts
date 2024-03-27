/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { HardhatRuntimeEnvironment } from 'hardhat/types';

import deployFactory from './deploy-factory';
import deployImplementation from './deploy-implementation';
import deployPaymaster from './deploy-paymaster';
import { ReleaseType } from './helpers/release';

export default async function (hre: HardhatRuntimeEnvironment): Promise<void> {
    console.log(`Taking a production release on ${hre.network.name}`);
    const implementation = await deployImplementation(
        hre,
        ReleaseType.production,
    );
    await deployFactory(hre, ReleaseType.production, implementation);
    await deployPaymaster(hre, ReleaseType.production);
}
