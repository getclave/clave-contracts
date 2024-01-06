// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {Errors} from './libraries/Errors.sol';
import {IClaveRegistry} from './interfaces/IClaveRegistry.sol';

contract ClaveRegistry is Ownable, IClaveRegistry {
    // Account factory contract address
    address factory;

    // Mapping of Clave accounts
    mapping(address => bool) public isClave;

    // Constructor function of the contracts
    constructor() Ownable() {}

    /**
     * @notice Registers an account as a Clave account
     * @dev Can only be called by the factory
     * @param account address - Address of the account to register
     */
    function register(address account) external override {
        if (msg.sender != factory) {
            revert Errors.NOT_FROM_FACTORY();
        }

        isClave[account] = true;
    }

    /**
     * @notice Sets a new factory contract
     * @dev Can only be called by the owner
     * @param factory_ address - Address of the new factory
     */
    function setFactory(address factory_) external onlyOwner {
        factory = factory_;
    }
}
