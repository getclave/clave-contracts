/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import elliptic from 'elliptic';
import { keccak256 } from 'ethers';
import BN from 'bn.js';

export function genKey(): elliptic.ec.KeyPair {
    const ec = new elliptic.ec('p256');
    return ec.genKeyPair();
}

export function genKeyK1(): elliptic.ec.KeyPair {
    const ec = new elliptic.ec('secp256k1');
    return ec.genKeyPair();
}

export function encodePublicKey(key: elliptic.ec.KeyPair): string {
    const pubKey = key.getPublic();
    const x = pubKey.getX().toString('hex').padStart(64, '0');
    const y = pubKey.getY().toString('hex').padStart(64, '0');

    return '0x' + x + y;
}

export function encodePublicKeyK1(key: elliptic.ec.KeyPair): string {
    const pubKey = key.getPublic();
    const x = pubKey.getX().toString('hex').padStart(64, '0');
    const y = pubKey.getY().toString('hex').padStart(64, '0');

    // Compute the Keccak-256 hash of the public key
    const buffer = Buffer.from(`${x}${y}`, 'hex');
    const hash = keccak256(buffer);
    // Extract the last 20 bytes (40 hex characters) of the hash
    const address = '0x' + hash.slice(-40);
    return address;
}

export function sign(msg: string, key: elliptic.ec.KeyPair): string {
    const buffer = Buffer.from(msg.slice(2), 'hex');
    const signature = key.sign(buffer, { canonical: true });

    const r = padToHex(signature.r, 64);
    const s = padToHex(signature.s, 64);

    if (isSecp256k1(key.ec.curve)) {
        const v = padToHex(new BN(signature.recoveryParam! + 27), 2);
        return `0x${r}${s}${v}`;
    }

    return `0x${r}${s}`;
}


function isSecp256k1(curve: any): boolean {
    return curve.type === 'short' && 
           curve.p.toString(16) === 'fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f';
}

function padToHex(value: BN | number, length: number): string {
    return value.toString(16).padStart(length, '0');
}