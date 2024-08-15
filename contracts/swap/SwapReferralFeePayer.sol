// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract SwapReferralFeePayer {
    using SafeERC20 for IERC20;

    event ReferralFee(address indexed receiver, address indexed token, uint256 fee);

    function payFee(
        address referrer,
        address token,
        uint256 feeReferrer,
        uint256 feeReferred
    ) external payable {
        if (token == address(0)) {
            (bool success, ) = payable(referrer).call{value: fee}('');
            require(success, 'ReferralFeePayer: failed to pay referral fee');
        } else {
            IERC20 erc20 = IERC20(token);
            erc20.safeTransferFrom(msg.sender, referrer, feeReferrer);
        }

        emit ReferralFee(referrer, token, feeReferrer);
        emit ReferralFee(msg.sender, token, feeReferred);
    }
}
