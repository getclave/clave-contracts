// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract ReferralFeePayer {
    event ReferralFee(address indexed referrer, address indexed token, uint256 fee);

    function payFee(address referrer, address token, uint256 fee) external returns (bool) {
        if (token == address(0)) {
            payable(referrer).transfer(fee);
            emit ReferralFee(referrer, token, fee);
            return true;
        } else {
            bool success = IERC20(token).transferFrom(msg.sender, referrer, fee);
            emit ReferralFee(referrer, token, fee);
            return success;
        }
    }
}
