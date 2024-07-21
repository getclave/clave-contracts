// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}

interface IWETH {
    function withdraw(uint256 amount) external;
}

interface IPancakeRouter {
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

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
    struct RewardData {
        uint256 rewardRate;
        uint256 rewardAmount;
        uint256 lastUpdate;
        uint256 rewardPerShare;
    }

    struct UserRewardData {
        uint256 claimable;
        uint256 debtRewardPerShare;
    }

    function stake(uint256 amount, address to) external returns (uint256);

    function userStaked(address recipient) external view returns (uint256);

    function rewardData(address token) external view returns (RewardData memory);

    function userRewardData(
        address token,
        address account
    ) external view returns (UserRewardData memory);
}

interface ISyncEarnRouter {
    function deposit(address pairAddress, uint256 minLiquidity) external payable;

    function stakePositions(
        address pairAddress,
        address recipient,
        address rewardToken
    ) external view returns (uint256[] memory tokensInPosition, uint256[] memory rewards);
}

interface ISyncPair is IERC20 {
    function getReserves() external view returns (uint256, uint256);
}

contract SyncEarnRouter is ISyncEarnRouter {
    using SafeERC20 for IERC20;

    uint256 private constant PRECISION = 1e24;

    ISyncRouter private syncRouter;
    ISyncStaking private syncStaking;
    IPancakeRouter private pancakeRouter;
    IWETH private weth;

    // Event to be emitted when a user deposits tokenA to the pair
    event Deposit(address indexed user, address indexed tokenA, uint256 indexed amount);
    event ClaimWithDust(address indexed account, address indexed token, uint amount);

    error INVALID_VALUE();
    error WITHDRAW_FAILED();

    constructor(
        address syncRouterAddress,
        address syncStakingAddress,
        address pancakeRouterAddress,
        address wethAddress
    ) {
        syncRouter = ISyncRouter(syncRouterAddress);
        syncStaking = ISyncStaking(syncStakingAddress);
        pancakeRouter = IPancakeRouter(pancakeRouterAddress);
        weth = IWETH(wethAddress);
    }

    receive() external payable {}

    /**
     * @notice View deposited token amounts for the tokenA and tokenB pair
     * @notice View claimable fees for tokenA and tokenB pair
     *
     * @param pairAddress address         - Depositing token address in the pair
     * @param recipient address           - Recipient address
     * @param rewardToken address         - Reward token address
     * @return tokensInPosition uint256[] - Deposited token amounts
     * @return rewards uint256[]          - Claimable fees
     */
    function stakePositions(
        address pairAddress,
        address recipient,
        address rewardToken
    ) external view override returns (uint256[] memory tokensInPosition, uint256[] memory rewards) {
        ISyncPair pair = ISyncPair(pairAddress);

        uint256 lpTokenBalance = syncStaking.userStaked(recipient);

        uint256 totalSupply = pair.totalSupply();

        (uint256 tokenAReserve, uint256 tokenBReserve) = pair.getReserves();

        uint256 tokenAAmount = (lpTokenBalance * tokenAReserve) / totalSupply;
        uint256 tokenBAmount = (lpTokenBalance * tokenBReserve) / totalSupply;

        tokensInPosition = new uint256[](2);

        tokensInPosition[0] = tokenAAmount;
        tokensInPosition[1] = tokenBAmount;

        rewards = new uint256[](2);

        ISyncStaking.RewardData memory rewardData = syncStaking.rewardData(rewardToken);
        ISyncStaking.UserRewardData memory userRewardData = syncStaking.userRewardData(
            rewardToken,
            recipient
        );

        uint256 rewardPerShare = rewardData.rewardPerShare;
        uint256 debtRewardPerShare = userRewardData.debtRewardPerShare;

        uint256 shareAfterLastUpdate = (rewardPerShare - debtRewardPerShare) * lpTokenBalance;
        uint256 rewardAfterLastUpdate = shareAfterLastUpdate / PRECISION;

        uint256 claimable = userRewardData.claimable;

        rewards[0] = 0;
        rewards[1] = claimable + rewardAfterLastUpdate;
    }

    function deposit(address pairAddress, uint256 minLiquidity) external payable override {
        IERC20 liquidityToken = IERC20(pairAddress);

        if (msg.value == 0) {
            revert INVALID_VALUE();
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

    function swapDust(IERC20 tokenIn, IERC20 tokenOut, uint256 amountToLeave) external {
        uint256 balance = tokenIn.balanceOf(msg.sender);
        uint256 amountToSwap = balance - amountToLeave;

        tokenIn.safeTransferFrom(msg.sender, address(this), amountToSwap);

        tokenIn.safeApprove(address(pancakeRouter), amountToSwap);

        if (address(tokenOut) == address(weth)) {
            uint256 amountOut = pancakeRouter.exactInputSingle(
                ExactInputSingleParams({
                    tokenIn: address(tokenIn),
                    tokenOut: address(tokenOut),
                    fee: 500,
                    recipient: address(this),
                    deadline: block.timestamp + 600000000,
                    amountIn: amountToSwap,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );

            weth.withdraw(amountOut);
            (bool success, ) = payable(msg.sender).call{value: amountOut}('');
            require(success, 'ETH transfer failed');
            emit ClaimWithDust(msg.sender, 0x000000000000000000000000000000000000800A, amountOut);
        } else {
            uint256 amountOut = pancakeRouter.exactInputSingle(
                ExactInputSingleParams({
                    tokenIn: address(tokenIn),
                    tokenOut: address(tokenOut),
                    fee: 500,
                    recipient: msg.sender,
                    deadline: block.timestamp + 600000000,
                    amountIn: amountToSwap,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
            emit ClaimWithDust(msg.sender, address(tokenOut), amountOut);
        }
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
            (bool success, ) = payable(msg.sender).call{value: amount}('');
            if (!success) revert WITHDRAW_FAILED();
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }
}
