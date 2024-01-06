// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {Transaction} from '@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import {IValidationHook, IExecutionHook} from '../interfaces/IHook.sol';

interface IClave {
    function setHookData(bytes32 key, bytes calldata data) external;

    function getHookData(address hook, bytes32 key) external view returns (bytes memory);
}

contract MockValidationHook is IValidationHook {
    bytes constant context = 'test-context';

    function init(bytes calldata) external override {}

    function disable() external override {}

    function validationHook(
        bytes32,
        Transaction calldata,
        bytes calldata hookData
    ) external pure override {
        bool shouldRevert = abi.decode(hookData, (bool));
        require(!shouldRevert);
    }

    function setHookData(address account, bytes32 key, bytes calldata data) external {
        IClave(account).setHookData(key, data);
    }

    function getHookData(
        address account,
        address hook,
        bytes32 key
    ) external view returns (bytes memory) {
        return IClave(account).getHookData(hook, key);
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IValidationHook).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

contract MockExecutionHook is IExecutionHook {
    bytes constant context = 'test-context';

    function init(bytes calldata) external override {}

    function disable() external override {}

    function preExecutionHook(
        Transaction calldata transaction
    ) external pure override returns (bytes memory context_) {
        require(transaction.value != 5);
        context_ = context;
    }

    function postExecutionHook(bytes memory context_) external pure override {
        require(keccak256(context_) == keccak256(context));
    }

    function setHookData(address account, bytes32 key, bytes calldata data) external {
        IClave(account).setHookData(key, data);
    }

    function getHookData(
        address account,
        address hook,
        bytes32 key
    ) external view returns (bytes memory) {
        return IClave(account).getHookData(hook, key);
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IExecutionHook).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
