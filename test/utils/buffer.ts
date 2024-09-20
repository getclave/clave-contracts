/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
export function bufferFromBase64url(base64url: string): Buffer {
    return Buffer.from(toBase64(base64url), 'base64');
}

export function bufferFromString(string: string): Buffer {
    return Buffer.from(string, 'utf8');
}

function toBase64(base64url: string | Buffer): string {
    base64url = base64url.toString();
    return padString(base64url).replace(/\-/g, '+').replace(/_/g, '/');
}

function padString(input: string): string {
    const segmentLength = 4;
    const stringLength = input.length;
    const diff = stringLength % segmentLength;

    if (!diff) {
        return input;
    }

    let position = stringLength;
    let padLength = segmentLength - diff;
    const paddedStringLength = stringLength + padLength;
    const buffer = Buffer.alloc(paddedStringLength);

    buffer.write(input);

    while (padLength--) {
        buffer.write('=', position++);
    }

    return buffer.toString();
}
