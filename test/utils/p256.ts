/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import elliptic from 'elliptic';
import { keccak256, ethers } from 'ethers';

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
    // Determine the curve type
    const curveType = key.ec.curve.type;

    const buffer = Buffer.from(msg.slice(2), 'hex');
    let signature: elliptic.ec.Signature;

    if (curveType === 'short' && key.ec.curve.p.toString(16) === 'fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f') {
        // This is secp256k1
        signature = key.sign(buffer, { canonical: true });
        const r = signature.r.toString('hex').padStart(64, '0');
        const s = signature.s.toString('hex').padStart(64, '0');
        const v = (signature.recoveryParam! + 27).toString(16).padStart(2, '0'); // Ensure v is two characters
        return '0x' + r + s + v;
    } else {
        // Assume this is P-256 (secp256r1) or another curve
        signature = key.sign(buffer);
        const r = signature.r.toString('hex').padStart(64, '0');
        const s = signature.s.toString('hex').padStart(64, '0');
        return '0x' + r + s;
    }
}
