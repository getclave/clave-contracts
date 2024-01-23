// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {Base64Url} from '../helpers/Base64Url.sol';
import {IR1Validator, IERC165} from '../interfaces/IValidator.sol';
import {Errors} from '../libraries/Errors.sol';

/**
 * @title validator contract for passkey r1 signatures
 * @author https://getclave.io
 */
contract PasskeyValidatorConstant is IR1Validator {
    address constant P256_VERIFIER = 0x4323cffC1Fda2da9928cB5A5A9dA45DC8Ee38a2f;
    string constant ClIENT_DATA_PREFIX = '{"type":"webauthn.get","challenge":"';
    string constant IOS_ClIENT_DATA_SUFFIX = '","origin":"https://getclave.io"}';
    string constant ANDROID_ClIENT_DATA_SUFFIX =
        '","origin":"android:apk-key-hash:-sYXRdwJA3hvue3mKpYrOZ9zSPC7b4mbgzJmdZEDO5w","androidPackageName":"com.clave.mobile"}';
    bytes constant AUTHENTICATOR_DATA =
        hex'175faf8504c2cdd7c01778a8b0efd4874ecb3aefd7ebb7079a941f7be8897d411d00000000';

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

    /**
     * @notice Calls the verifier function with given params
     * @param hash bytes32         - Signed data hash
     * @param rs bytes32[2]        - Signature array for the r and s values
     * @param pubKey bytes32[2]    - Public key coordinates array for the x and y values
     * @return - bool - Return the success of the verification
     */
    function callVerifier(
        bytes32 hash,
        bytes32[2] memory rs,
        bytes32[2] memory pubKey
    ) private view returns (bool) {
        /**
         * Prepare the input format
         * input[  0: 32] = signed data hash
         * input[ 32: 64] = signature r
         * input[ 64: 96] = signature s
         * input[ 96:128] = public key x
         * input[128:160] = public key y
         */
        bytes memory input = abi.encodePacked(hash, rs[0], rs[1], pubKey[0], pubKey[1]);
        // Make a call to verify the signature
        (bool success, bytes memory data) = P256_VERIFIER.staticcall(input);
        uint256 returnValue;
        // Return true if the call was successful and the return value is 1
        if (success && data.length > 0) {
            assembly {
                returnValue := mload(add(data, 0x20))
            }
            if (returnValue == 1) return true;
        }
        // Otherwise return false for the unsucessful calls and invalid signatures
        return false;
    }

    function _validateSignature(
        bytes32 challenge,
        bytes calldata signature,
        bytes32[2] calldata pubKey
    ) private view returns (bool valid) {
        bool isAndroid = signature[0] == 0x00;
        bytes32[2] memory rs = abi.decode(signature[1:], (bytes32[2]));
        bytes memory challengeBase64 = bytes(Base64Url.encode(bytes.concat(challenge)));
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

        valid = callVerifier(message, rs, pubKey);
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

        bytes memory challengeBase64 = bytes(Base64Url.encode(bytes.concat(challenge)));
        bytes memory clientData = bytes.concat(
            bytes(ClIENT_DATA_PREFIX),
            challengeBase64,
            bytes(clientDataSuffix)
        );

        bytes32 message = _createMessage(authenticatorData, clientData);

        valid = callVerifier(message, rs, pubKey);
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
