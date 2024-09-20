/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { sha256 } from 'ethers';

import { bufferFromBase64url, bufferFromString } from './buffer';

// hash of 'https://getclave.io' + (BE, BS, UP, UV) flags set + unincremented sign counter
const authData = bufferFromBase64url(
    'F1-vhQTCzdfAF3iosO_Uh07LOu_X67cHmpQfe-iJfUEdAAAAAA',
);
const clientDataPrefix = bufferFromString(
    '{"type":"webauthn.get","challenge":"',
);
const clientDataSuffix = bufferFromString('","origin":"https://getclave.io"}');

export function getSignedData(challenge: string): string {
    const challengeBuffer = Buffer.from(challenge.slice(2), 'hex');
    const challengeBase64 = challengeBuffer.toString('base64url');
    const clientData = Buffer.concat([
        clientDataPrefix,
        bufferFromString(challengeBase64),
        clientDataSuffix,
    ]);

    const clientDataHash = Buffer.from(sha256(clientData).slice(2), 'hex');

    return sha256(Buffer.concat([authData, clientDataHash]));
}
