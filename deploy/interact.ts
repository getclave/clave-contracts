/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import * as hre from 'hardhat';

import { getWallet } from './utils';

// Address of the contract to interact with
const CONTRACT_ADDRESS = '0x...';
// Name of the contract to interact with
const CONTRACT_NAME = 'Example';

// An example of a script to interact with the contract
// Do not push modifications to this file
// Just modify, interact then revert changes
export default async function (): Promise<void> {
    console.log(`Running script to interact with contract ${CONTRACT_ADDRESS}`);

    const contract = await hre.ethers.getContractAt(
        CONTRACT_NAME,
        CONTRACT_ADDRESS,
        getWallet(hre),
    );

    // Run contract read function
    const response = await contract.greet();
    console.log(`Current message is: ${response}`);

    // Run contract write function
    const transaction = await contract.setGreeting('Hello people!');
    console.log(`Transaction hash of setting new message: ${transaction.hash}`);

    // Wait until transaction is processed
    await transaction.wait();
}
