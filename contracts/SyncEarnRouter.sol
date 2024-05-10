// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface ISyncRouter {
    struct TokenInput {
        address token;
        uint256 amount;
        bool useVault;
    }

    struct TokenAmount {
        address token;
        uint256 amount;
    }

    function addLiquidity2(
        address pool,
        TokenInput[] calldata inputs,
        bytes calldata data,
        uint256 minLiquidity,
        address callback,
        bytes calldata callbackData,
        address staking
    ) external payable returns (uint256 liquidity);
}

interface ISyncStaking {
    function stake(uint256 amount, address to) external returns (uint256);
}

interface ISyncEarnRouter {
    function deposit(address pairAddress, uint256 minLiquidity) external payable;
}

contract SyncEarnRouter is ISyncEarnRouter {
    using SafeERC20 for IERC20;

    ISyncRouter private syncRouter;
    ISyncStaking private syncStaking;

    // Event to be emitted when a user deposits tokenA to the pair
    event Deposit(address indexed user, address indexed tokenA, uint256 indexed amount);

    error InvalidValue();

    constructor(address syncRouterAddress, address syncStakingAddress) {
        syncRouter = ISyncRouter(syncRouterAddress);
        syncStaking = ISyncStaking(syncStakingAddress);
    }

    function deposit(address pairAddress, uint256 minLiquidity) external payable override {
        IERC20 liquidityToken = IERC20(pairAddress);

        if (msg.value == 0) {
            revert InvalidValue();
        }

        // Add liquidity
        ISyncRouter.TokenInput[] memory inputs = new ISyncRouter.TokenInput[](1);
        inputs[0] = ISyncRouter.TokenInput({token: address(0), amount: msg.value, useVault: false});

        uint256 liquidity = syncRouter.addLiquidity2{value: msg.value}(
            pairAddress,
            inputs,
            abi.encode(address(this)),
            minLiquidity,
            address(0),
            '0x',
            address(0)
        );

        // Approve LP token to staking contract
        liquidityToken.safeApprove(address(syncStaking), liquidity);

        // Stake LP tokens
        syncStaking.stake(liquidity, msg.sender);

        emit Deposit(msg.sender, address(0), msg.value);
    }

    /**
     * @notice Withdraw token from the contract for the emergency cases
     *
     * @param token address  - Token address to withdraw
     * @param amount uint256 - Amount to withdraw
     *
     * @dev Not a real case, so everyone can withdraw
     * @dev token = address(0) if ETH
     */
    function withdrawToken(address token, uint256 amount) external {
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }
}
