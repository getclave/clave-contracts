/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { appendFileSync } from 'fs';
import { env } from 'process';
import { read } from 'read-last-lines';

// Adds headers to snapshot file to specify what are the gas costs for
export async function snapshotHeader(header: string): Promise<void> {
    // Check if we are in snapshot mode
    if (env.NODE_ENV == 'snapshot') {
        // This prevents race conditions
        while (
            !(await read('./.gas-snapshot', 1)).trim().endsWith('(opcodes)')
        ) {
            await sleep(50);
        }
        appendFileSync('./.gas-snapshot', `\n"${header}"\n`);
    }
}

export async function snapshotFirstHeader(header: string): Promise<void> {
    // Check if we are in snapshot mode
    if (env.NODE_ENV === 'snapshot') {
        appendFileSync('./.gas-snapshot', `\n"${header}"\n`);
    }
}

async function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => {
        setTimeout(resolve, ms);
    });
}
