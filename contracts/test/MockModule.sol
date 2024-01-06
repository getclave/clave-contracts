// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import {IModule} from '../interfaces/IModule.sol';

interface IClave {
    function executeFromModule(address to, uint256 value, bytes memory data) external;

    function k1AddOwner(address addr) external;
}

contract MockModule is IModule {
    mapping(address => uint256) public values;

    function init(bytes calldata initData) external override {
        values[msg.sender] = abi.decode(initData, (uint256));
    }

    function disable() external override {
        delete values[msg.sender];
    }

    function testExecuteFromModule(address account, address to) external {
        uint256 value = values[account];
        IClave(account).executeFromModule(to, value, '');
    }

    function testOnlySelfOrModule(address account) external {
        IClave(account).k1AddOwner(address(this));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IModule).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
