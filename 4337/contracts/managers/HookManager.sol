// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC165Checker} from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import {UserOperation} from '@account-abstraction/contracts/interfaces/UserOperation.sol';

import {Auth} from '../auth/Auth.sol';
import {ClaveStorage} from '../libraries/ClaveStorage.sol';
import {AddressLinkedList} from '../libraries/LinkedList.sol';
import {Errors} from '../libraries/Errors.sol';
import {IExecutionHook, IValidationHook} from '../interfaces/IHook.sol';
import {IInitable} from '../interfaces/IInitable.sol';
import {IClave} from '../interfaces/IClave.sol';
import {ExcessivelySafeCall} from '@nomad-xyz/excessively-safe-call/src/ExcessivelySafeCall.sol';

/**
 * @title Manager contract for hooks
 * @notice Abstract contract for managing the enabled hooks of the account
 * @dev Hook addresses are stored in a linked list
 * @author https://getclave.io
 */
abstract contract HookManager is Auth, IClave {
    // Helper library for address to address mappings
    using AddressLinkedList for mapping(address => address);
    // Interface helper library
    using ERC165Checker for address;
    // Low level calls helper library
    using ExcessivelySafeCall for address;

    // Slot for execution hooks to store context
    bytes32 private constant CONTEXT_KEY = keccak256('HookManager.context');

    /**
     * @notice Event emitted when a hook is added
     * @param hook address - Address of the added hook
     */
    event AddHook(address indexed hook);

    /**
     * @notice Event emitted when a hook is removed
     * @param hook address - Address of the removed hook
     */
    event RemoveHook(address indexed hook);

    /**
     * @notice Add a hook to the list of hooks and call it's init function
     * @dev Can only be called by self or a module
     * @param hookAndData bytes calldata - Address of the hook and data to initialize it with
     * @param isValidation bool          - True if the hook is a validation hook, false otherwise
     */
    function addHook(bytes calldata hookAndData, bool isValidation) external onlySelfOrModule {
        _addHook(hookAndData, isValidation);
    }

    /**
     * @notice Remove a hook from the list of hooks and call it's disable function
     * @dev Can only be called by self or a module
     * @param hook address      - Address of the hook to remove
     * @param isValidation bool - True if the hook is a validation hook, false otherwise
     */
    function removeHook(address hook, bool isValidation) external onlySelfOrModule {
        _removeHook(hook, isValidation);
    }

    /**
     * @notice Allow a hook to store data in the contract
     * @dev Can only be called by a hook
     * @param key bytes32         - Slot to store data at
     * @param data bytes calldata - Data to store
     */
    function setHookData(bytes32 key, bytes calldata data) external onlyHook {
        if (key == CONTEXT_KEY) {
            revert Errors.INVALID_KEY();
        }

        _hookDataStore()[msg.sender][key] = data;
    }

    /**
     * @notice Get the data stored by a hook
     * @param hook address  - Address of the hook to retrieve data for
     * @param key bytes32   - Slot to retrieve data from
     * @return bytes memory - Data stored at the slot
     */
    function getHookData(address hook, bytes32 key) external view returns (bytes memory) {
        return _hookDataStore()[hook][key];
    }

    /**
     * @notice Check if an address is in the list of hooks
     * @param addr address - Address to check
     * @return bool        - True if the address is a hook, false otherwise
     */
    function isHook(address addr) external view returns (bool) {
        return _isHook(addr);
    }

    /**
     * @notice Get the list of validation or execution hooks
     * @param isValidation bool          - True if the list of validation hooks should be returned, false otherwise
     * @return hookList address[] memory - List of validation or exeuction hooks
     */
    function listHooks(bool isValidation) external view returns (address[] memory hookList) {
        if (isValidation) {
            hookList = _validationHooksLinkedList().list();
        } else {
            hookList = _executionHooksLinkedList().list();
        }
    }

    // Runs the validation hooks that are enabled by the account and returns true if none reverts
    function runValidationHooks(
        bytes32 userOpHash,
        UserOperation calldata userOp,
        bytes[] memory hookData
    ) internal returns (bool) {
        mapping(address => address) storage validationHooks = _validationHooksLinkedList();

        address cursor = validationHooks[AddressLinkedList.SENTINEL_ADDRESS];
        uint256 idx = 0;
        // Iterate through hooks
        while (cursor > AddressLinkedList.SENTINEL_ADDRESS) {
            // Call it with corresponding hookData
            bool success = _call(
                cursor,
                abi.encodeWithSelector(
                    IValidationHook.validationHook.selector,
                    userOpHash,
                    userOp,
                    hookData[idx++]
                )
            );

            if (!success) {
                return false;
            }

            cursor = validationHooks[cursor];
        }

        return true;
    }

    // Runs the execution hooks that are enabled by the account before and after _execute
    modifier runExecutionHooks(
        address to,
        uint256 value,
        bytes calldata data
    ) {
        mapping(address => address) storage executionHooks = _executionHooksLinkedList();

        address cursor = executionHooks[AddressLinkedList.SENTINEL_ADDRESS];
        // Iterate through hooks
        while (cursor > AddressLinkedList.SENTINEL_ADDRESS) {
            // Call the preExecutionHook function with transaction struct
            bytes memory context = IExecutionHook(cursor).preExecutionHook(to, value, data);
            // Store returned data as context
            _setContext(cursor, context);

            cursor = executionHooks[cursor];
        }

        _;

        cursor = executionHooks[AddressLinkedList.SENTINEL_ADDRESS];
        // Iterate through hooks
        while (cursor > AddressLinkedList.SENTINEL_ADDRESS) {
            bytes memory context = _getContext(cursor);
            if (context.length > 0) {
                // Call the postExecutionHook function with stored context
                IExecutionHook(cursor).postExecutionHook(context);
                // Delete context
                _deleteContext(cursor);
            }

            cursor = executionHooks[cursor];
        }
    }

    function _addHook(bytes calldata hookAndData, bool isValidation) internal {
        if (hookAndData.length < 20) {
            revert Errors.EMPTY_HOOK_ADDRESS();
        }

        address hookAddress = address(bytes20(hookAndData[0:20]));

        if (!_supportsHook(hookAddress, isValidation)) {
            revert Errors.HOOK_ERC165_FAIL();
        }

        bytes calldata initData = hookAndData[20:];

        if (isValidation) {
            _validationHooksLinkedList().add(hookAddress);
        } else {
            _executionHooksLinkedList().add(hookAddress);
        }

        IInitable(hookAddress).init(initData);

        emit AddHook(hookAddress);
    }

    function _removeHook(address hook, bool isValidation) internal {
        if (isValidation) {
            _validationHooksLinkedList().remove(hook);
        } else {
            _executionHooksLinkedList().remove(hook);
        }

        (bool success, ) = hook.excessivelySafeCall(
            gasleft(),
            0,
            0,
            abi.encodeWithSelector(IInitable.disable.selector)
        );
        (success); // silence unused local variable warning

        emit RemoveHook(hook);
    }

    function _isHook(address addr) internal view override returns (bool) {
        return
            _validationHooksLinkedList().exists(addr) || _executionHooksLinkedList().exists(addr);
    }

    function _setContext(address hook, bytes memory context) private {
        _hookDataStore()[hook][CONTEXT_KEY] = context;
    }

    function _deleteContext(address hook) private {
        delete _hookDataStore()[hook][CONTEXT_KEY];
    }

    function _getContext(address hook) private view returns (bytes memory context) {
        context = _hookDataStore()[hook][CONTEXT_KEY];
    }

    function _call(address target, bytes memory data) private returns (bool success) {
        assembly ('memory-safe') {
            success := call(gas(), target, 0, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function _validationHooksLinkedList()
        private
        view
        returns (mapping(address => address) storage validationHooks)
    {
        validationHooks = ClaveStorage.layout().validationHooks;
    }

    function _executionHooksLinkedList()
        private
        view
        returns (mapping(address => address) storage executionHooks)
    {
        executionHooks = ClaveStorage.layout().executionHooks;
    }

    function _hookDataStore()
        private
        view
        returns (mapping(address => mapping(bytes32 => bytes)) storage hookDataStore)
    {
        hookDataStore = ClaveStorage.layout().hookDataStore;
    }

    function _supportsHook(address hook, bool isValidation) internal view returns (bool) {
        return
            isValidation
                ? hook.supportsInterface(type(IValidationHook).interfaceId)
                : hook.supportsInterface(type(IExecutionHook).interfaceId);
    }
}
