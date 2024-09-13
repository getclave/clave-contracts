// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {Errors} from './libraries/Errors.sol';
import {IClaveRegistry} from './interfaces/IClaveRegistry.sol';

contract ClaveRegistry is Ownable, IClaveRegistry {
    mapping(address => bool) public isFactory;
    // Mapping of Clave accounts
    mapping(address => bool) public isClave;

    /**
     * @notice Event emmited when a factory contract is set
     * @param factory address - Address of the factory contract
     */
    event FactorySet(address indexed factory);

    /**
     * @notice Event emmited when a factory contract is unset
     * @param factory address - Address of the factory contract
     */
    event FactoryUnset(address indexed factory);

    // Constructor function of the contracts
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Registers an account as a Clave account
     * @dev Can only be called by the factory or owner
     * @param account address - Address of the account to register
     */
    function register(address account) external override {
        if (!isFactory[msg.sender] && msg.sender != owner()) {
            revert Errors.NOT_FROM_FACTORY();
        }

        isClave[account] = true;
    }

    /**
     * @notice Registers multiple accounts as Clave accounts
     * @dev Can only be called by the factory or owner
     * @param accounts address[] - Array of addresses to register
     */
    function registerMultiple(address[] calldata accounts) external {
        if (!isFactory[msg.sender] && msg.sender != owner()) {
            revert Errors.NOT_FROM_FACTORY();
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            isClave[accounts[i]] = true;
        }
    }

    /**
     * @notice Unregisters an account as a Clave account
     * @dev Can only be called by the factory or owner
     * @param account address - Address of the account to unregister
     */
    function unregister(address account) external {
        if (!isFactory[msg.sender] && msg.sender != owner()) {
            revert Errors.NOT_FROM_FACTORY();
        }

        isClave[account] = false;
    }

    /**
     * @notice Unregisters multiple accounts as Clave accounts
     * @dev Can only be called by the factory or owner
     * @param accounts address[] - Array of addresses to unregister
     */
    function unregisterMultiple(address[] calldata accounts) external {
        if (!isFactory[msg.sender] && msg.sender != owner()) {
            revert Errors.NOT_FROM_FACTORY();
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            isClave[accounts[i]] = false;
        }
    }

    /**
     * @notice Sets a new factory contract
     * @dev Can only be called by the owner
     * @param factory_ address - Address of the new factory
     */
    function setFactory(address factory_) external onlyOwner {
        isFactory[factory_] = true;

        emit FactorySet(factory_);
    }

    /**
     * @notice Unsets a factory contract
     * @dev Can only be called by the owner
     * @param factory_ address - Address of the factory
     */
    function unsetFactory(address factory_) external onlyOwner {
        isFactory[factory_] = false;

        emit FactoryUnset(factory_);
    }
}
