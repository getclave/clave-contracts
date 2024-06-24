/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { readFile } from 'fs/promises';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Provider, Wallet } from 'zksync-ethers';

const CLAVE_NAME_SERVICE_ADDRESS = '0x';
const CHUNK_SIZE = 100;
const STARTING_INDEX = 0;

export default async function (hre: HardhatRuntimeEnvironment): Promise<void> {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const provider = new Provider(hre.network.config.url);
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const privateKey = process.env.PRIVATE_KEY!;
    const wallet = new Wallet(privateKey).connect(provider);

    const registry = await hre.ethers.getContractAt(
        'ClaveNameService',
        CLAVE_NAME_SERVICE_ADDRESS,
        wallet,
    );

    let currentIndex = STARTING_INDEX;
    try {
        const fileContent = await readFile(
            './deploy/migration-data.json',
            'utf-8',
        );
        const data: { result: { rows: Array<{ address: string }> } } =
            JSON.parse(fileContent);

        const addresses = data.result.rows.map((row) => row.address);

        while (currentIndex < addresses.length) {
            const chunk = addresses.slice(
                currentIndex,
                currentIndex + CHUNK_SIZE,
            );

            const tx = await registry.connect(wallet).registerMultiple(chunk);
            await tx.wait();

            currentIndex += CHUNK_SIZE;

            console.log('chunk processed:', currentIndex, 'with tx:', tx.hash);
        }
    } catch (e) {
        console.log('Error while processing chunk:', currentIndex);
        console.log(e);
    }
}
