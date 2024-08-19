// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {Base64} from '../helpers/Base64.sol';
import {IR1Validator, IERC165} from '../interfaces/IValidator.sol';
import {Errors} from '../libraries/Errors.sol';
import {VerifierCaller} from '../helpers/VerifierCaller.sol';

/**
 * @title validator contract for passkey r1 signatures
 * @author https://getclave.io
 */
contract PasskeyValidator is IR1Validator, VerifierCaller {
    address constant P256_VERIFIER = 0x840Fec7b1615375E66f9631aBdA962dADeBFFf20;
    string constant ClIENT_DATA_PREFIX = '{"type":"webauthn.get","challenge":"';
    string constant IOS_ClIENT_DATA_SUFFIX = '","origin":"https://getclave.io"}';
    string constant ANDROID_ClIENT_DATA_SUFFIX =
        '","origin":"android:apk-key-hash:-sYXRdwJA3hvue3mKpYrOZ9zSPC7b4mbgzJmdZEDO5w","androidPackageName":"com.clave.mobile"}';
    // hash of 'https://getclave.io' + (BE, BS, UP, UV) flags set + unincremented sign counter
    bytes constant AUTHENTICATOR_DATA =
        hex'175faf8504c2cdd7c01778a8b0efd4874ecb3aefd7ebb7079a941f7be8897d411d00000000';
    // user presence and user verification flags
    bytes1 constant AUTH_DATA_MASK = 0x05;
    // maximum value for 's' in a secp256r1 signature
    bytes32 constant lowSmax = 0x7fffffff800000007fffffffffffffffde737d56d38bcf4279dce5617e3192a8;

    /// @inheritdoc IR1Validator
    function validateSignature(
        bytes32 challenge,
        bytes calldata signature,
        bytes32[2] calldata pubKey
    ) external view returns (bool valid) {
        if (signature.length == 65) {
            valid = _validateSignature(challenge, signature, pubKey);
        } else {
            valid = _validateFatSignature(challenge, signature, pubKey);
        }
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IR1Validator).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function _validateSignature(
        bytes32 challenge,
        bytes calldata signature,
        bytes32[2] calldata pubKey
    ) private view returns (bool valid) {
        bool isAndroid = signature[0] == 0x00;
        bytes32[2] memory rs = abi.decode(signature[1:], (bytes32[2]));

        // malleability check
        if (rs[1] > lowSmax) {
            return false;
        }

        bytes memory challengeBase64 = bytes(Base64.encodeURL(bytes.concat(challenge)));
        bytes memory clientData;
        if (isAndroid) {
            clientData = bytes.concat(
                bytes(ClIENT_DATA_PREFIX),
                challengeBase64,
                bytes(ANDROID_ClIENT_DATA_SUFFIX)
            );
        } else {
            clientData = bytes.concat(
                bytes(ClIENT_DATA_PREFIX),
                challengeBase64,
                bytes(IOS_ClIENT_DATA_SUFFIX)
            );
        }

        bytes32 message = _createMessage(AUTHENTICATOR_DATA, clientData);

        valid = callVerifier(P256_VERIFIER, message, rs, pubKey);
    }

    function _validateFatSignature(
        bytes32 challenge,
        bytes calldata fatSignature,
        bytes32[2] calldata pubKey
    ) private view returns (bool valid) {
        (
            bytes memory authenticatorData,
            string memory clientDataSuffix,
            bytes32[2] memory rs
        ) = _decodeFatSignature(fatSignature);

        // malleability check
        if (rs[1] > lowSmax) {
            return false;
        }

        // check if the flags are set
        if (authenticatorData[32] & AUTH_DATA_MASK != AUTH_DATA_MASK) {
            return false;
        }

        bytes memory challengeBase64 = bytes(Base64.encodeURL(bytes.concat(challenge)));
        bytes memory clientData = bytes.concat(
            bytes(ClIENT_DATA_PREFIX),
            challengeBase64,
            bytes(clientDataSuffix)
        );

        bytes32 message = _createMessage(authenticatorData, clientData);

        valid = callVerifier(P256_VERIFIER, message, rs, pubKey);
    }

    function _createMessage(
        bytes memory authenticatorData,
        bytes memory clientData
    ) private pure returns (bytes32 message) {
        bytes32 clientDataHash = sha256(clientData);
        message = sha256(bytes.concat(authenticatorData, clientDataHash));
    }

    function _decodeFatSignature(
        bytes memory fatSignature
    )
        private
        pure
        returns (
            bytes memory authenticatorData,
            string memory clientDataSuffix,
            bytes32[2] memory rs
        )
    {
        (authenticatorData, clientDataSuffix, rs) = abi.decode(
            fatSignature,
            (bytes, string, bytes32[2])
        );
    }
}
