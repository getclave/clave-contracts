/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import elliptic from 'elliptic';
import { keccak256 } from 'ethers';
import BN from 'bn.js';
import { ethers } from 'ethers';

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

export async function sign(msg: string, key: elliptic.ec.KeyPair, chainId: bigint, validatorAddress: string): Promise<string> {
    if (isSecp256k1(key.ec.curve)) {
        const privateKey = padToHex(key.getPrivate().toString(16), 64);
        const wallet = new ethers.Wallet(privateKey);
        
        const signedTxHash = msg.startsWith('0x') ? msg : '0x' + msg;
        
        const domain = {
            name: 'zkSync',
            version: '2',
            chainId: chainId.toString(),
            verifyingContract: validatorAddress,
        };
        
        const types = {
            SignMessage: [
                { name: 'details', type: 'string' },
                { name: 'hash', type: 'bytes32' }
            ]
        };
        
        const value = {
            details: "You are signing a hash of your transaction",
            hash: signedTxHash
        };
        
        // Sign the typed data
        return await wallet.signTypedData(domain, types, value);
    } else {
        // For non-secp256k1, directly sign the message
        const signatureBuffer = Buffer.from(msg.slice(2), 'hex');
        const signature = key.sign(signatureBuffer, { canonical: true });
        const r = padToHex(signature.r.toString(16), 64);
        const s = padToHex(signature.s.toString(16), 64);
        return `0x${r}${s}`;
    }
}


function isSecp256k1(curve: any): boolean {
    return curve.type === 'short' && 
           curve.p.toString(16) === 'fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f';
}

function padToHex(value: string | BN | number, length: number): string {
    let hexString: string;

    if (typeof value === 'string') {
        // If it's already a string, just ensure it's a hex string
        hexString = value.startsWith('0x') ? value.slice(2) : value;
    } else if (BN.isBN(value)) {
        // If it's a BN instance, convert to hex string
        hexString = value.toString(16);
    } else if (typeof value === 'number') {
        // If it's a number, convert to hex string
        hexString = value.toString(16);
    } else {
        throw new Error('Invalid input type for padToHex');
    }

    // Pad the hex string to the desired length
    return hexString.padStart(length, '0');
}