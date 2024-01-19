// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Base64Url} from '../helpers/Base64Url.sol';
import {IR1Validator, IERC165} from '../interfaces/IValidator.sol';
import {Errors} from '../libraries/Errors.sol';

contract PasskeyValidatorConstant is IR1Validator {
    address constant P256_VERIFIER = 0x4323cffC1Fda2da9928cB5A5A9dA45DC8Ee38a2f;

    function validateSignature(
        bytes32 signedHash,
        bytes calldata fatSignature,
        bytes32[2] calldata pubKey
    ) external view returns (bool valid) {
        (
            bytes memory authenticatorData,
            bytes1 authenticatorDataFlagMask,
            bytes memory clientData,
            bytes32 clientChallenge,
            uint256 clientChallengeDataOffset,
            bytes32[2] memory rs
        ) = decodeFatSignature(fatSignature);

        bool isValidChallenge = validateChallenge(signedHash, clientChallenge);
        bool isValidAuthData = validateAuthData(authenticatorData, authenticatorDataFlagMask);
        bool isValidClientData = validateClientData(
            clientData,
            clientChallenge,
            clientChallengeDataOffset
        );

        bytes32 message = createMessage(authenticatorData, clientData);

        bool isValidSig = callVerifier(message, rs, pubKey);

        if (isValidChallenge && isValidAuthData && isValidClientData && isValidSig) {
            valid = true;
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

    /**
     * @notice This function allows validating the client challenge
     * @dev The client challenge must be the hash of the data to be validated
     * @param signedHash bytes32            - Hash of the data to be validated
     * @param clientChallenge bytes32 - Client challenge obtained by the fat signature
     * @return valid bool - True if the client challenge is valid, false otherwise
     */
    function validateChallenge(
        bytes32 signedHash,
        bytes32 clientChallenge
    ) private pure returns (bool valid) {
        valid = signedHash == clientChallenge;
    }

    /**
     * @notice This function allows validating the authenticator data
     * @dev Validates by checking the 33rd byte of the authenticator data
     * @dev Flag mask should be 0x01 for user presence and 0x04 for user verification
     * @param authenticatorData bytes          - Authenticator data obtained by the fat signature
     * @param authenticatorDataFlagMask bytes1 - Authenticator data flag mask obtained by the fat signature
     * @return valid bool - True if the authenticator data is valid, false otherwise
     */

    function validateAuthData(
        bytes memory authenticatorData,
        bytes1 authenticatorDataFlagMask
    ) private pure returns (bool valid) {
        valid = (authenticatorData[32] & authenticatorDataFlagMask) == authenticatorDataFlagMask;
    }

    /**
     * @notice This function allows validating the client data
     * @dev Checks if client data contains base64url encoded client challenge at the offset
     * @param clientData bytes                  - Client data obtained by the fat signature
     * @param clientChallenge bytes32           - Client challenge obtained by the fat signature
     * @param clientChallengeDataOffset uint256 - Offset of client challenge in client data obtained from fat signature
     * @return valid bool - True if the client data is valid, false otherwise
     */
    function validateClientData(
        bytes memory clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset
    ) private pure returns (bool valid) {
        bytes memory challengeExtracted = new bytes(
            bytes(Base64Url.encode(abi.encodePacked(clientChallenge))).length
        );

        copyBytes(
            clientData,
            clientChallengeDataOffset,
            challengeExtracted.length,
            challengeExtracted,
            0
        );

        valid =
            keccak256(bytes(Base64Url.encode(abi.encodePacked(clientChallenge)))) ==
            keccak256(challengeExtracted);
    }

    /**
     * @notice Compute the webauthn message from the authenticator data and client data
     * @param authenticatorData bytes - Authenticator data obtained by the fat signature
     * @param clientData bytes        - Client data obtained by the fat signature
     * @return message bytes32 - Webauthn message to be used for signature validation
     */
    function createMessage(
        bytes memory authenticatorData,
        bytes memory clientData
    ) private pure returns (bytes32 message) {
        bytes memory verifyData = new bytes(authenticatorData.length + 32);

        copyBytes(authenticatorData, 0, authenticatorData.length, verifyData, 0);

        copyBytes(
            abi.encodePacked(sha256(clientData)),
            0,
            32,
            verifyData,
            authenticatorData.length
        );

        message = sha256(verifyData);
    }

    /**
     * @notice Helper function for copying from one place in memory to another
     * @param _from bytes         - Source byte array to copy from
     * @param _fromOffset uint256 - Starting point in the source array to begin copying from
     * @param _length uint256     - Number of bytes to be copied
     * @param _to bytes           - Destination byte array to copy to
     * @param _toOffset uint256   - Position in the destination array where copied bytes will be placed
     * @return _to bytes          - Returns the destination byte array
     */

    function copyBytes(
        bytes memory _from,
        uint256 _fromOffset,
        uint256 _length,
        bytes memory _to,
        uint256 _toOffset
    ) private pure returns (bytes memory) {
        uint256 minLength = _length + _toOffset;
        require(_to.length >= minLength, '[copyBytes] Buffer too small.');
        // The offset 32 is added to skip the size field of both bytes variables
        uint256 i = 32 + _fromOffset;
        uint256 j = 32 + _toOffset;
        while (i < (32 + _fromOffset + _length)) {
            assembly {
                let tmp := mload(add(_from, i))
                mstore(add(_to, j), tmp)
            }
            i += 32;
            j += 32;
        }
        return _to;
    }

    /**
     * @notice This function allows decoding a WebAuthn signature to appropriate formatted data types
     * @param fatSignature bytes - Signature in fat format to be decoded
     * @return authenticatorData bytes           - Collection of data about the authentication, including information about the authenticator
     * @return authenticatorDataFlagMask bytes1  - 0x01 for user presence and 0x04 for user verification
     * @return clientData bytes                  - Contextual information regarding the authentication request
     * @return clientChallenge bytes32           - Hash of the data to be validated
     * @return clientChallengeDataOffset uint256 - Offset of client challenge in client data
     * @return rs bytes32[2]                     - Signature in [r,s] format
     */
    function decodeFatSignature(
        bytes memory fatSignature
    )
        private
        pure
        returns (
            bytes memory authenticatorData,
            bytes1 authenticatorDataFlagMask,
            bytes memory clientData,
            bytes32 clientChallenge,
            uint256 clientChallengeDataOffset,
            bytes32[2] memory rs
        )
    {
        (
            authenticatorData,
            authenticatorDataFlagMask,
            clientData,
            clientChallenge,
            clientChallengeDataOffset,
            rs
        ) = abi.decode(fatSignature, (bytes, bytes1, bytes, bytes32, uint256, bytes32[2]));
    }
}
