/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { readFile, writeFile } from 'fs/promises';
import { ethers } from 'hardhat';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Provider, Wallet } from 'zksync-ethers';

const ADDRESS_FILE = './deploy/wallets-staging.json';
const INDEX_FILE = './deploy/last-migrate-index.txt';
const CLAVE_NAME_SERVICE_ADDRESS = '0xC6F5A612835188866A0ABEAd3E77EB768B85Bb1D';
const CHUNK_SIZE = 20;

const getStartingIndex = async (fileName: string): Promise<number> => {
    try {
        const fileContent = await readFile(fileName, 'utf-8');
        return Number(fileContent);
    } catch (e) {
        return 0;
    }
};

const setStartingIndex = async (
    fileName: string,
    idx: number,
): Promise<void> => {
    await writeFile(fileName, idx.toString(), { encoding: 'utf-8' });
};

type ClaveWallet = { username: string | null; address: string };
const filterWallets = (walletData: string): Array<ClaveWallet> => {
    const data: Array<ClaveWallet> = JSON.parse(walletData);

    return data
        .map(({ address, username }) => {
            try {
                return {
                    address: ethers.getAddress(address.toLowerCase()),
                    username,
                };
            } catch {
                return { address: '0x', username };
            }
        })
        .filter(({ address }) => address != '0x');
};

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

    let currentIndex = await getStartingIndex(INDEX_FILE);
    console.log(`[migrate] starting from #${currentIndex}`);
    try {
        const fileContent = await readFile(ADDRESS_FILE, 'utf-8');
        console.log(`[migrate] file read: ${JSON.parse(fileContent).length}`);

        const addresses = filterWallets(fileContent).map((r) => r.address);
        console.log(`[migrate] found ${addresses.length} addresses`);

        while (currentIndex < addresses.length) {
            const chunk = addresses.slice(
                currentIndex,
                currentIndex + CHUNK_SIZE,
            );

            const tx = await registry.connect(wallet).registerMultiple(chunk);
            await tx.wait();

            currentIndex += CHUNK_SIZE;
            await setStartingIndex(INDEX_FILE, currentIndex);

            console.log(`[migrate] #${currentIndex} done, (${tx.hash})`);
        }
        console.log('[migrate] complete');
    } catch (e) {
        console.log(`[migrate] error #${currentIndex}:`);
        console.log(e);
    }
}
