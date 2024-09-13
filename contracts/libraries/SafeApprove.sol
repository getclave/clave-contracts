// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

library SafeApprove {
    using SafeERC20 for IERC20;

    function safeApprove(IERC20 token, address spender, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance > amount) {
            uint256 decreaseAmount = currentAllowance - amount;
            token.safeDecreaseAllowance(spender, decreaseAmount);
        } else if (currentAllowance < amount) {
            uint256 increaseAmount = amount - currentAllowance;
            token.safeIncreaseAllowance(spender, increaseAmount);
        }
    }
}