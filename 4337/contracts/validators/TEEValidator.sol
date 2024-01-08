// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IR1Validator, IERC165} from '../interfaces/IValidator.sol';
import {Errors} from '../libraries/Errors.sol';

/**
 * @title secp256r1 ec keys' signature validator contract implementing its interface
 * @author https://getclave.io
 */
contract TEEValidator is IR1Validator {
    //dummy value
    address immutable P256_VERIFIER;

    /**
     * @notice Constructor function of the validator
     * @param p256VerifierAddress address - Address of the p256 verifier contract
     */
    constructor(address p256VerifierAddress) {
        P256_VERIFIER = p256VerifierAddress;
    }

    /// @inheritdoc IR1Validator
    function validateSignature(
        bytes32 signedHash,
        bytes calldata signature,
        bytes32[2] calldata pubKey
    ) external view override returns (bool valid) {
        bytes32[2] memory rs = abi.decode(signature, (bytes32[2]));

        valid = callVerifier(signedHash, rs, pubKey);
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
}
