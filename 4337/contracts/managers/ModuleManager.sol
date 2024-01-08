// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC165Checker} from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';

import {ClaveStorage} from '../libraries/ClaveStorage.sol';
import {Auth} from '../auth/Auth.sol';
import {AddressLinkedList} from '../libraries/LinkedList.sol';
import {Errors} from '../libraries/Errors.sol';
import {IModule} from '../interfaces/IModule.sol';
import {IInitable} from '../interfaces/IInitable.sol';
import {IClave} from '../interfaces/IClave.sol';
import {ExcessivelySafeCall} from '@nomad-xyz/excessively-safe-call/src/ExcessivelySafeCall.sol';

/**
 * @title Manager contract for modules
 * @notice Abstract contract for managing the enabled modules of the account
 * @dev Module addresses are stored in a linked list
 * @author https://getclave.io
 */
abstract contract ModuleManager is Auth, IClave {
    // Helper library for address to address mappings
    using AddressLinkedList for mapping(address => address);
    // Interface helper library
    using ERC165Checker for address;
    // Low level calls helper library
    using ExcessivelySafeCall for address;

    /**
     * @notice Event emitted when a module is added
     * @param module address - Address of the added module
     */
    event AddModule(address indexed module);

    /**
     * @notice Event emitted when a module is removed
     * @param module address - Address of the removed module
     */
    event RemoveModule(address indexed module);

    /**
     * @notice Add a module to the list of modules and call it's init function
     * @dev Can only be called by self or a module
     * @param moduleAndData bytes calldata - Address of the module and data to initialize it with
     */
    function addModule(bytes calldata moduleAndData) external onlySelfOrModule {
        _addModule(moduleAndData);
    }

    /**
     * @notice Remove a module from the list of modules and call it's disable function
     * @dev Can only be called by self or a module
     * @param module address - Address of the module to remove
     */
    function removeModule(address module) external onlySelfOrModule {
        _removeModule(module);
    }

    /**
     * @notice Allow modules to execute arbitrary calls on behalf of the account
     * @dev Can only be called by a module
     * @param to address - Address to call
     * @param value uint256 - Eth to send with call
     * @param data bytes memory - Data to make the call with
     */
    function executeFromModule(address to, uint256 value, bytes memory data) external onlyModule {
        if (to == address(this)) revert Errors.RECUSIVE_MODULE_CALL();

        assembly {
            let result := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @notice Check if an address is in the list of modules
     * @param addr address - Address to check
     * @return bool - True if the address is a module, false otherwise
     */
    function isModule(address addr) external view returns (bool) {
        return _isModule(addr);
    }

    /**
     * @notice Get the list of modules
     * @return moduleList address[] memory - List of modules
     */
    function listModules() external view returns (address[] memory moduleList) {
        moduleList = _modulesLinkedList().list();
    }

    function _addModule(bytes calldata moduleAndData) internal {
        if (moduleAndData.length < 20) {
            revert Errors.EMPTY_MODULE_ADDRESS();
        }

        address moduleAddress = address(bytes20(moduleAndData[0:20]));
        bytes calldata initData = moduleAndData[20:];

        if (!_supportsModule(moduleAddress)) {
            revert Errors.MODULE_ERC165_FAIL();
        }

        _modulesLinkedList().add(moduleAddress);

        IModule(moduleAddress).init(initData);

        emit AddModule(moduleAddress);
    }

    function _removeModule(address module) internal {
        _modulesLinkedList().remove(module);

        (bool success, ) = module.excessivelySafeCall(
            gasleft(),
            0,
            0,
            abi.encodeWithSelector(IInitable.disable.selector)
        );
        (success); // silence unused local variable warning

        emit RemoveModule(module);
    }

    function _isModule(address addr) internal view override returns (bool) {
        return _modulesLinkedList().exists(addr);
    }

    function _modulesLinkedList()
        private
        view
        returns (mapping(address => address) storage modules)
    {
        modules = ClaveStorage.layout().modules;
    }

    function _supportsModule(address module) internal view returns (bool) {
        return module.supportsInterface(type(IModule).interfaceId);
    }
}
