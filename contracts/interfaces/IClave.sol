// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IAccount} from '@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IAccount.sol';

import {IERC1271Upgradeable} from '@openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol';

import {IHookManager} from './IHookManager.sol';
import {IModuleManager} from './IModuleManager.sol';
import {IOwnerManager} from './IOwnerManager.sol';
import {IUpgradeManager} from './IUpgradeManager.sol';
import {IValidatorManager} from './IValidatorManager.sol';

// interface IClave is IAccount {
interface IClave is
    IAccount,
    IERC1271Upgradeable,
    IHookManager,
    IModuleManager,
    IOwnerManager,
    IUpgradeManager,
    IValidatorManager
{

}
