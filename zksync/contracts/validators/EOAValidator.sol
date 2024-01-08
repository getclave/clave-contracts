// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IK1Validator, IERC165} from '../interfaces/IValidator.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/**
 * @title secp256k1 ec keys' signature validator contract implementing its interface
 * @author https://getclave.io
 */
contract EOAValidator is IK1Validator {
    // ECDSA library to make verifications
    using ECDSA for bytes32;

    /// @inheritdoc IK1Validator
    function validateSignature(
        bytes32 signedHash,
        bytes calldata signature
    ) external pure override returns (address signer) {
        (signer, ) = signedHash.tryRecover(signature);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IK1Validator).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
