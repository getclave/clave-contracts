// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {UserOperation} from '@account-abstraction/contracts/interfaces/UserOperation.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import {IInitable} from './IInitable.sol';

interface IValidationHook is IInitable, IERC165 {
    function validationHook(
        bytes32 signedHash,
        UserOperation calldata userOp,
        bytes calldata hookData
    ) external;
}

interface IExecutionHook is IInitable, IERC165 {
    function preExecutionHook(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory context);

    function postExecutionHook(bytes memory context) external;
}
