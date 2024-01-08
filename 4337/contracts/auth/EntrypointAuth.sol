// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IEntryPoint} from '@account-abstraction/contracts/interfaces/IEntryPoint.sol';

import {Errors} from '../libraries/Errors.sol';

/**
 * @title EntrypointAuth
 * @notice Abstract contract that allows only calls from entrypoint
 * @author https://getclave.io
 */
abstract contract EntrypointAuth {
    function entrypoint() public view virtual returns (IEntryPoint);

    modifier onlyEntrypoint() {
        if (msg.sender != address(entrypoint())) {
            revert Errors.NOT_FROM_ENTRYPOINT();
        }
        _;
    }
}
