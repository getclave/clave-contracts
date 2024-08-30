// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IK1Validator, IERC165} from "../interfaces/IValidator.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EOAValidator is IK1Validator {
    using ECDSA for bytes32;

    bytes32 private constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant SIGN_MESSAGE_TYPEHASH =
        keccak256("SignMessage(string details,bytes32 hash)");

    function validateSignature(
        bytes32 signedTxHash,
        bytes calldata signature
    ) external view returns (address signer) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes("zkSync")),
                keccak256(bytes("2")),
                block.chainid,
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                SIGN_MESSAGE_TYPEHASH,
                keccak256(bytes("You are signing a hash of your transaction")),
                signedTxHash
            )
        );
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        signer = ECDSA.recover(messageHash, signature);
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) external pure override returns (bool) {
        return
            interfaceId == type(IK1Validator).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
