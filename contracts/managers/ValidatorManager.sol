// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC165Checker} from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';

import {Auth} from '../auth/Auth.sol';
import {Errors} from '../libraries/Errors.sol';
import {ClaveStorage} from '../libraries/ClaveStorage.sol';
import {AddressLinkedList} from '../libraries/LinkedList.sol';
import {IR1Validator, IK1Validator} from '../interfaces/IValidator.sol';

/**
 * @title Manager contract for validators
 * @notice Abstract contract for managing the validators of the account
 * @dev Validators are stored in a linked list
 */
abstract contract ValidatorManager is Auth {
    // Helper library for address to address mappings
    using AddressLinkedList for mapping(address => address);
    // Interface helper library
    using ERC165Checker for address;

    /**
     * @notice Event emitted when a r1 validator is added
     * @param validator address - Address of the added r1 validator
     */
    event R1AddValidator(address indexed validator);

    /**
     * @notice Event emitted when a k1 validator is added
     * @param validator address - Address of the added k1 validator
     */
    event K1AddValidator(address indexed validator);

    /**
     * @notice Event emitted when a r1 validator is removed
     * @param validator address - Address of the removed r1 validator
     */
    event R1RemoveValidator(address indexed validator);

    /**
     * @notice Event emitted when a k1 validator is removed
     * @param validator address - Address of the removed k1 validator
     */
    event K1RemoveValidator(address indexed validator);

    /**
     * @notice Adds a validator to the list of r1 validators
     * @dev Can only be called by self or a whitelisted module
     * @param validator address - Address of the r1 validator to add
     */
    function r1AddValidator(address validator) external onlySelfOrModule {
        _r1AddValidator(validator);
    }

    /**
     * @notice Adds a validator to the list of k1 validators
     * @dev Can only be called by self or a whitelisted module
     * @param validator address - Address of the k1 validator to add
     */
    function k1AddValidator(address validator) external onlySelfOrModule {
        _k1AddValidator(validator);
    }

    /**
     * @notice Removes a validator from the list of r1 validators
     * @dev Can only be called by self or a whitelisted module
     * @dev Can not remove the last validator
     * @param validator address - Address of the validator to remove
     */
    function r1RemoveValidator(address validator) external onlySelfOrModule {
        _r1RemoveValidator(validator);
    }

    /**
     * @notice Removes a validator from the list of k1 validators
     * @dev Can only be called by self or a whitelisted module
     * @param validator address - Address of the validator to remove
     */
    function k1RemoveValidator(address validator) external onlySelfOrModule {
        _k1RemoveValidator(validator);
    }

    /**
     * @notice Checks if an address is in the r1 validator list
     * @param validator address -Address of the validator to check
     * @return True if the address is a validator, false otherwise
     */
    function r1IsValidator(address validator) external view returns (bool) {
        return _r1IsValidator(validator);
    }

    /**
     * @notice Checks if an address is in the k1 validator list
     * @param validator address - Address of the validator to check
     * @return True if the address is a validator, false otherwise
     */
    function k1IsValidator(address validator) external view returns (bool) {
        return _k1IsValidator(validator);
    }

    /**
     * @notice Returns the list of r1 validators
     * @return validatorList address[] memory - Array of r1 validator addresses
     */
    function r1ListValidators() external view returns (address[] memory validatorList) {
        validatorList = _r1ValidatorsLinkedList().list();
    }

    /**
     * @notice Returns the list of k1 validators
     * @return validatorList address[] memory - Array of k1 validator addresses
     */
    function k1ListValidators() external view returns (address[] memory validatorList) {
        validatorList = _k1ValidatorsLinkedList().list();
    }

    function _r1AddValidator(address validator) internal {
        if (!_supportsR1(validator)) {
            revert Errors.VALIDATOR_ERC165_FAIL();
        }

        _r1ValidatorsLinkedList().add(validator);

        emit R1AddValidator(validator);
    }

    function _k1AddValidator(address validator) internal {
        if (!_supportsK1(validator)) {
            revert Errors.VALIDATOR_ERC165_FAIL();
        }

        _k1ValidatorsLinkedList().add(validator);

        emit K1AddValidator(validator);
    }

    function _r1RemoveValidator(address validator) internal {
        _r1ValidatorsLinkedList().remove(validator);

        if (_r1ValidatorsLinkedList().isEmpty()) {
            revert Errors.EMPTY_R1_VALIDATORS();
        }

        emit R1RemoveValidator(validator);
    }

    function _k1RemoveValidator(address validator) internal {
        _k1ValidatorsLinkedList().remove(validator);

        emit K1RemoveValidator(validator);
    }

    function _r1IsValidator(address validator) internal view returns (bool) {
        return _r1ValidatorsLinkedList().exists(validator);
    }

    function _k1IsValidator(address validator) internal view returns (bool) {
        return _k1ValidatorsLinkedList().exists(validator);
    }

    function _supportsR1(address validator) internal view returns (bool) {
        return validator.supportsInterface(type(IR1Validator).interfaceId);
    }

    function _supportsK1(address validator) internal view returns (bool) {
        return validator.supportsInterface(type(IK1Validator).interfaceId);
    }

    function _r1ValidatorsLinkedList()
        private
        view
        returns (mapping(address => address) storage r1Validators)
    {
        r1Validators = ClaveStorage.layout().r1Validators;
    }

    function _k1ValidatorsLinkedList()
        private
        view
        returns (mapping(address => address) storage k1Validators)
    {
        k1Validators = ClaveStorage.layout().k1Validators;
    }
}
