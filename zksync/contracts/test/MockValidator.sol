// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IR1Validator, IERC165} from '../interfaces/IValidator.sol';
import {Transaction} from '@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol';

/**
 * @title Mock validator contract implementing r1validator interface
 * @author https://getclave.io
 */
contract MockValidator is IR1Validator {
    function validateSignature(
        bytes32,
        bytes calldata,
        bytes32[2] calldata
    ) external pure override returns (bool valid) {
        valid = true;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IR1Validator).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
