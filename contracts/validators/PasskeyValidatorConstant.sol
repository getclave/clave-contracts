// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Base64Url} from '../helpers/Base64Url.sol';
import {IR1Validator, IERC165} from '../interfaces/IValidator.sol';
import {Errors} from '../libraries/Errors.sol';

contract PasskeyValidatorConstant is IR1Validator {
    address constant P256_VERIFIER = 0x4323cffC1Fda2da9928cB5A5A9dA45DC8Ee38a2f;
    string constant ClIENT_DATA_PREFIX = '{"type":"webauthn.get","challenge":"';
    string constant ClIENT_DATA_SUFFIX = '","origin":"https://getclave.io"}';
    bytes constant AUTHENTICATOR_DATA =
        hex'175faf8504c2cdd7c01778a8b0efd4874ecb3aefd7ebb7079a941f7be8897d411d00000000';

    function validateSignature(
        bytes32 challenge,
        bytes calldata signature,
        bytes32[2] calldata pubKey
    ) external view returns (bool valid) {
        bytes memory challengeBase64 = bytes(Base64Url.encode(bytes.concat(challenge)));
        bytes memory clientData = bytes.concat(
            bytes(ClIENT_DATA_PREFIX),
            challengeBase64,
            bytes(ClIENT_DATA_SUFFIX)
        );
        bytes32[2] memory rs = abi.decode(signature, (bytes32[2]));

        bytes32 message = createMessage(AUTHENTICATOR_DATA, clientData);

        bool isValidSig = callVerifier(message, rs, pubKey);

        if (isValidSig) {
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
}
