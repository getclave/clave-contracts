/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { task } from 'hardhat/config';

import { deployContract } from '../deploy/utils';

task('deploy', 'Task for deploying contracts')
    .addFlag(
        'silent',
        'If true, the deployment process will not print any logs',
    )
    .addFlag(
        'noVerify',
        'If true, the contract will not be verified on Block Explorer',
    )
    .addPositionalParam(
        'contractArtifactName',
        'The name of the contract artifact to deploy',
    )
    .addOptionalVariadicPositionalParam(
        'constructorArguments',
        'The arguments for the contract constructor',
    )
    .setAction(async (taskArgs, hre) => {
        const contractArtifactName = taskArgs.contractArtifactName;
        const constructorArguments = taskArgs.constructorArguments;
        const options = {
            silent: taskArgs.silent,
            noVerify: taskArgs.noVerify,
        };

        await deployContract(
            hre,
            contractArtifactName,
            constructorArguments,
            options,
        );
    });
