/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import type { AddressKey } from '@getclave/constants';
import fs from 'fs';
import path from 'path';

export enum ReleaseType {
    production = 'PRODUCTION',
    development = 'TEST',
}

export const updateAddress = (
    type: ReleaseType,
    key: AddressKey,
    address: string,
): void => {
    const filePath = path.resolve(__dirname, addressPath);
    let fileContent = fs.readFileSync(filePath, 'utf8');

    const regex = getRegex(type, key);

    fileContent = fileContent.replace(regex, `$1${address}$2`);

    fs.writeFileSync(filePath, fileContent, 'utf8');
};

export async function loadAddress(
    type: ReleaseType | undefined,
    key: AddressKey,
): Promise<string> {
    const constants = await import('@getclave/constants');
    if (type === ReleaseType.production) {
        return constants.CONSTANT_ADDRESSES_PRODUCTION[key];
    } else {
        return constants.CONSTANT_ADDRESSES_TEST[key];
    }
}

const addressPath = '../../../../packages/clave-constants/src/address/index.ts';

const getRegex = (type: ReleaseType, key: AddressKey): RegExp => {
    return new RegExp(
        `(CONSTANT_ADDRESSES_${type}: Record<AddressKey, string> = {[^}]*${key}: ')[^']*(')`,
        's',
    );
};
