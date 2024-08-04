/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import * as hre from 'hardhat';

import { deployContract } from './utils';

// An example of a basic deploy script
// Do not push modifications to this file
// Just modify, interact then revert changes
export default async function (): Promise<void> {
    const contractArtifactName = 'Example';
    const constructorArguments = ['Clave', 324];
    await deployContract(hre, contractArtifactName, constructorArguments);
}
