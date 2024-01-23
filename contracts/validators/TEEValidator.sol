// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IR1Validator, IERC165} from '../interfaces/IValidator.sol';
import {Errors} from '../libraries/Errors.sol';
import {VerifierCaller} from '../helpers/VerifierCaller.sol';

/**
 * @title secp256r1 ec keys' signature validator contract implementing its interface
 * @author https://getclave.io
 */
contract TEEValidator is IR1Validator, VerifierCaller {
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

        valid = callVerifier(P256_VERIFIER, signedHash, rs, pubKey);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IR1Validator).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
