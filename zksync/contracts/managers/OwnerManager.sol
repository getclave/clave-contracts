// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ClaveStorage} from '../libraries/ClaveStorage.sol';
import {BytesLinkedList, AddressLinkedList} from '../libraries/LinkedList.sol';
import {Errors} from '../libraries/Errors.sol';
import {Auth} from '../auth/Auth.sol';
import {IClave} from '../interfaces/IClave.sol';

/**
 * @title Manager contract for owners
 * @notice Abstract contract for managing the owners of the account
 * @dev R1 Owners are 64 byte secp256r1 public keys
 * @dev K1 Owners are secp256k1 addresses
 * @dev Owners are stored in a linked list
 * @author https://getclave.io
 */
abstract contract OwnerManager is Auth, IClave {
    // Helper library for bytes to bytes mappings
    using BytesLinkedList for mapping(bytes => bytes);
    // Helper library for address to address mappings
    using AddressLinkedList for mapping(address => address);

    /**
     * @notice Event emitted when a r1 owner is added
     * @param pubKey bytes - r1 owner that has been added
     */
    event R1AddOwner(bytes pubKey);

    /**
     * @notice Event emitted when a k1 owner is added
     * @param addr address - k1 owner that has been added
     */
    event K1AddOwner(address indexed addr);

    /**
     * @notice Event emitted when a r1 owner is removed
     * @param pubKey bytes - r1 owner that has been removed
     */
    event R1RemoveOwner(bytes pubKey);

    /**
     * @notice Event emitted when a k1 owner is removed
     * @param addr address - k1 owner that has been removed
     */
    event K1RemoveOwner(address indexed addr);

    /**
     * @notice Event emitted when all owners are cleared
     */
    event ResetOwners();

    /**
     * @notice Adds a r1 owner to the list of r1 owners
     * @dev Can only be called by self or a whitelisted module
     * @dev Public Key length must be 64 bytes
     * @param pubKey bytes calldata - Public key to add to the list of r1 owners
     */
    function r1AddOwner(bytes calldata pubKey) external onlySelfOrModule {
        _r1AddOwner(pubKey);
    }

    /**
     * @notice Adds a k1 owner to the list of k1 owners
     * @dev Can only be called by self or a whitelisted module
     * @dev Address can not be the zero address
     * @param addr address - Address to add to the list of k1 owners
     */
    function k1AddOwner(address addr) external onlySelfOrModule {
        _k1AddOwner(addr);
    }

    /**
     * @notice Removes a r1 owner from the list of r1 owners
     * @dev Can only be called by self or a whitelisted module
     * @dev Can not remove the last r1 owner
     * @param pubKey bytes calldata - Public key to remove from the list of r1 owners
     */
    function r1RemoveOwner(bytes calldata pubKey) external onlySelfOrModule {
        _r1RemoveOwner(pubKey);
    }

    /**
     * @notice Removes a k1 owner from the list of k1 owners
     * @dev Can only be called by self or a whitelisted module
     * @param addr address - Address to remove from the list of k1 owners
     */
    function k1RemoveOwner(address addr) external onlySelfOrModule {
        _k1RemoveOwner(addr);
    }

    /**
     * @notice Clears both r1 owners and k1 owners and adds an r1 owner
     * @dev Can only be called by self or a whitelisted module
     * @dev Public Key length must be 64 bytes
     * @param pubKey bytes calldata - new r1 owner to add
     */
    function resetOwners(bytes calldata pubKey) external override onlySelfOrModule {
        _r1ClearOwners();
        _k1ClearOwners();

        emit ResetOwners();

        _r1AddOwner(pubKey);
    }

    /**
     * @notice Checks if an Public Key is in the list of r1 owners
     * @param pubKey bytes calldata - Public key to check
     * @return bool - True if the Public Key is in the list, false otherwise
     */
    function r1IsOwner(bytes calldata pubKey) external view returns (bool) {
        return _r1IsOwner(pubKey);
    }

    /**
     * @notice Checks if an address is in the list of k1 owners
     * @param addr address - Address to check
     * @return bool - True if the address is in the list, false otherwise
     */
    function k1IsOwner(address addr) external view returns (bool) {
        return _k1IsOwner(addr);
    }

    /**
     * @notice Returns the list of r1 owners
     * @return r1OwnerList bytes[] memory - Array of r1 owner public keys
     */
    function r1ListOwners() external view returns (bytes[] memory r1OwnerList) {
        r1OwnerList = _r1OwnersLinkedList().list();
    }

    /**
     * @notice Returns the list of k1 owners
     * @return k1OwnerList address[] memory - Array of k1 owner addresses
     */
    function k1ListOwners() external view returns (address[] memory k1OwnerList) {
        k1OwnerList = _k1OwnersLinkedList().list();
    }

    function _r1AddOwner(bytes calldata pubKey) internal {
        if (pubKey.length != 64) {
            revert Errors.INVALID_PUBKEY_LENGTH();
        }

        _r1OwnersLinkedList().add(pubKey);

        emit R1AddOwner(pubKey);
    }

    function _k1AddOwner(address addr) internal {
        _k1OwnersLinkedList().add(addr);

        emit K1AddOwner(addr);
    }

    function _r1RemoveOwner(bytes calldata pubKey) internal {
        _r1OwnersLinkedList().remove(pubKey);

        if (_r1OwnersLinkedList().isEmpty()) {
            revert Errors.EMPTY_R1_OWNERS();
        }

        emit R1RemoveOwner(pubKey);
    }

    function _k1RemoveOwner(address addr) internal {
        _k1OwnersLinkedList().remove(addr);

        emit K1RemoveOwner(addr);
    }

    function _r1IsOwner(bytes calldata pubKey) internal view returns (bool) {
        return _r1OwnersLinkedList().exists(pubKey);
    }

    function _k1IsOwner(address addr) internal view returns (bool) {
        return _k1OwnersLinkedList().exists(addr);
    }

    function _r1OwnersLinkedList()
        internal
        view
        returns (mapping(bytes => bytes) storage r1Owners)
    {
        r1Owners = ClaveStorage.layout().r1Owners;
    }

    function _k1OwnersLinkedList()
        internal
        view
        returns (mapping(address => address) storage k1Owners)
    {
        k1Owners = ClaveStorage.layout().k1Owners;
    }

    function _r1ClearOwners() private {
        _r1OwnersLinkedList().clear();
    }

    function _k1ClearOwners() private {
        _k1OwnersLinkedList().clear();
    }
}
