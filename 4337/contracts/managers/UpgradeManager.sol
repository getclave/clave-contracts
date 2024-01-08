// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {Errors} from '../libraries/Errors.sol';
import {Auth} from '../auth/Auth.sol';

/**
 * @title Upgrade Manager
 * @notice Abstract contract for managing the upgrade process of the account
 */
abstract contract UpgradeManager is Auth {
    // keccak-256 of "eip1967.proxy.implementation" subtracted by 1
    bytes32 private constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice Event emitted when the contract is upgraded
     * @param oldImplementation address - Address of the old implementation contract
     * @param newImplementation address - Address of the new implementation contract
     */
    event Upgraded(address indexed oldImplementation, address indexed newImplementation);

    /**
     * @notice Upgrades the account contract to a new implementation
     * @dev Can only be called by self
     * @param newImplementation address - Address of the new implementation contract
     */
    function upgradeTo(address newImplementation) external onlySelf {
        address oldImplementation;
        assembly {
            oldImplementation := and(
                sload(_IMPLEMENTATION_SLOT),
                0xffffffffffffffffffffffffffffffffffffffff
            )
        }
        if (oldImplementation == newImplementation) {
            revert Errors.SAME_IMPLEMENTATION();
        }
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }

        emit Upgraded(oldImplementation, newImplementation);
    }

    /**
     * @notice Returns the current implementation address
     * @return address - Address of the current implementation contract
     */
    function implementation() external view returns (address) {
        address impl;
        assembly {
            impl := and(sload(_IMPLEMENTATION_SLOT), 0xffffffffffffffffffffffffffffffffffffffff)
        }

        return impl;
    }
}
