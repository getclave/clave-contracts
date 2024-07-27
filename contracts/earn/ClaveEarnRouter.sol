// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IZtake {
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);
}

contract ClaveEarnRouter {
    address public stakingAddress;

    constructor(address _stakingAddress) {
        stakingAddress = _stakingAddress;
    }

    function stakePositions(
        address account
    ) external view returns (uint256[] memory tokensInPosition, uint256[] memory rewards) {
        IZtake staking = IZtake(stakingAddress);
        uint256 balance = staking.balanceOf(account);
        uint256 earned = staking.earned(account);
        tokensInPosition = new uint256[](2);
        rewards = new uint256[](2);
        tokensInPosition[0] = balance;
        rewards[0] = earned;
    }
}
