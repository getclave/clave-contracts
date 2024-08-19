// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract SwapReferralFeePayer {
    using SafeERC20 for IERC20;

    event ReferralFee(address indexed referrer, address indexed token, uint256 fee);
    event Cashback(address indexed referred, address indexed token, uint256 fee);

    function payFee(
        address referrer,
        address token,
        uint256 fee,
        uint256 cashback
    ) external payable {
        if (referrer != address(0)) {
            if (token == address(0)) {
                (bool success, ) = payable(referrer).call{value: fee}('');
                require(success, 'ReferralFeePayer: failed to pay referral fee');
            } else {
                IERC20 erc20 = IERC20(token);
                erc20.safeTransferFrom(msg.sender, referrer, fee);
            }

            emit ReferralFee(referrer, token, fee);
        }

        if (cashback != 0) {
            emit Cashback(msg.sender, token, cashback);
        }
    }
}
