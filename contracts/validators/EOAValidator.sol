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
        bytes32 eip712Hash,
        bytes calldata signature
    ) external pure override returns (address signer) {
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", eip712Hash)
        );
        // Recover the signer
        signer = ethSignedMessageHash.recover(signature);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IK1Validator).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
