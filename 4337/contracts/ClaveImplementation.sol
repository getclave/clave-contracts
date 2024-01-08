// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {TokenCallbackHandler} from '@account-abstraction/contracts/samples/callback/TokenCallbackHandler.sol';
import {IAccount} from '@account-abstraction/contracts/interfaces/IAccount.sol';
import {IEntryPoint} from '@account-abstraction/contracts/interfaces/IEntryPoint.sol';
import {UserOperation, UserOperationLib} from '@account-abstraction/contracts/interfaces/UserOperation.sol';

import {HookManager} from './managers/HookManager.sol';
import {ModuleManager} from './managers/ModuleManager.sol';
import {UpgradeManager} from './managers/UpgradeManager.sol';

import {Errors} from './libraries/Errors.sol';
import {SignatureDecoder} from './libraries/SignatureDecoder.sol';

import {ERC1271Handler} from './handlers/ERC1271Handler.sol';

/**
 * @title Main account contract for the Clave wallet infrastructure in zkSync Era
 * @author https://getclave.io
 */
contract ClaveImplementation is
    Initializable,
    IAccount,
    HookManager,
    ModuleManager,
    UpgradeManager,
    ERC1271Handler,
    TokenCallbackHandler
{
    uint256 internal constant SIG_OK = 0;
    uint256 internal constant SIG_FAILED = 1;

    IEntryPoint private immutable _ENTRYPOINT;

    constructor(IEntryPoint entryPoint) {
        _ENTRYPOINT = entryPoint;
        _disableInitializers();
    }

    /**
     * @notice Initializer function for the account contract
     * @param initialR1Owner bytes calldata - The initial r1 owner of the account
     * @param initialR1Validator address    - The initial r1 validator of the account
     * @param modules bytes[] calldata      - The list of modules to enable for the account
     */
    function initialize(
        bytes calldata initialR1Owner,
        address initialR1Validator,
        bytes[] calldata modules
    ) external initializer {
        _r1AddOwner(initialR1Owner);
        _r1AddValidator(initialR1Validator);

        for (uint256 i = 0; i < modules.length; ) {
            _addModule(modules[i]);
            unchecked {
                i++;
            }
        }
    }

    // Receive function to allow ETHs
    receive() external payable {}

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external onlyEntrypoint returns (uint256 validationData) {
        validationData = _validateUserOp(userOp, userOpHash);
        _payPrefund(missingAccountFunds);
    }

    function execute(address to, uint256 value, bytes calldata data) external onlyEntrypoint {
        _execute(to, value, data);
    }

    function executeBatch(
        address[] calldata to,
        uint256[] calldata value,
        bytes[] calldata data
    ) external onlyEntrypoint {
        require(to.length == data.length && to.length == value.length, 'wrong array lengths');
        for (uint256 i = 0; i < to.length; i++) {
            _execute(to[i], value[i], data[i]);
        }
    }

    function addDeposit() external payable {
        entrypoint().depositTo{value: msg.value}(address(this));
    }

    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) external onlyEntrypoint {
        entrypoint().withdrawTo(withdrawAddress, amount);
    }

    function getDeposit() external view returns (uint256) {
        return entrypoint().balanceOf(address(this));
    }

    function entrypoint() public view override returns (IEntryPoint) {
        return _ENTRYPOINT;
    }

    function getNonce() public view returns (uint256) {
        return entrypoint().getNonce(address(this), 0);
    }

    function _validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal returns (uint256 validationData) {
        // Extract the signature, validator address and hook data from the userOp.signature
        (bytes memory signature, address validator, bytes[] memory hookData) = SignatureDecoder
            .decodeSignature(userOp.signature);

        // Run validation hooks
        bool hookSuccess = runValidationHooks(userOpHash, userOp, hookData);

        if (!hookSuccess) {
            return SIG_FAILED;
        }

        bool valid = _handleValidation(validator, userOpHash, signature);

        validationData = valid ? SIG_OK : SIG_FAILED;
    }

    function _execute(
        address to,
        uint256 value,
        bytes calldata data
    ) internal runExecutionHooks(to, value, data) {
        (bool success, bytes memory result) = to.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }('');
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }
}
