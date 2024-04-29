// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface IKoiRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool[] calldata stable
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        uint256 feeType,
        bool stable
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool stable
    ) external returns (uint256 amountA, uint256 amountB);

    function pairFor(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (address pair);

    function getReserves(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (uint256 reserveA, uint256 reserveB);
}

interface IKoiEarnRouter {
    function deposit(
        address tokenAAddress,
        address tokenBAddress,
        uint256 tokenAmount,
        uint256 feeType,
        bool isStable,
        uint256 slippageRate
    ) external;

    function withdraw(
        address tokenAAddress,
        address tokenBAddress,
        uint256 lpTokenAmount,
        bool isStable,
        uint256 slippageRate
    ) external;
}

/**
 * @title KoiEarnRouter
 * @author https://getclave.io
 */
contract KoiEarnRouter is IKoiEarnRouter {
    using SafeERC20 for IERC20;

    IKoiRouter private koiRouter;

    constructor(address koiRouterAddress) {
        koiRouter = IKoiRouter(koiRouterAddress);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }

    /**
     * @notice Deposit tokenA for the tokenA and tokenB to the pair
     *
     * @param tokenAAddress address      - Depositing token address in the pair
     * @param tokenBAddress address      - Side token address in the pair
     * @param tokenAmount uint256        - Depositing token amount
     * @param isStable bool              - Stable pair or not
     * @param slippageRate uint256       - Slippage rate over 10_000
     *
     * @dev Input 9_950 for slippage rate for 0,5% slippage
     */
    function deposit(
        address tokenAAddress,
        address tokenBAddress,
        uint256 tokenAmount,
        uint256 feeType,
        bool isStable,
        uint256 slippageRate
    ) external override {
        IERC20 tokenA = IERC20(tokenAAddress);
        IERC20 tokenB = IERC20(tokenBAddress);

        tokenA.safeTransferFrom(msg.sender, address(this), tokenAmount);

        (uint256 tokenAReserve, uint256 tokenBReserve) = koiRouter.getReserves(
            tokenAAddress,
            tokenBAddress,
            isStable
        );

        (uint256 desiredA, uint256 desiredB) = desiredAmounts(
            tokenAmount,
            tokenAReserve,
            tokenBReserve
        );

        tokenA.safeApprove(address(koiRouter), tokenAmount);

        address[] memory swapPath = new address[](2);
        swapPath[0] = tokenAAddress;
        swapPath[1] = tokenBAddress;

        bool[] memory isStableArr = new bool[](1);
        isStableArr[0] = isStable;

        uint256 receivedBAmount = koiRouter.swapExactTokensForTokens(
            tokenAmount - desiredA,
            (desiredB * slippageRate) / 10_000,
            swapPath,
            address(this),
            block.timestamp + 10_000,
            isStableArr
        )[1];

        tokenB.safeApprove(address(koiRouter), receivedBAmount);

        (uint256 amountA, uint256 amountB, ) = koiRouter.addLiquidity(
            tokenAAddress,
            tokenBAddress,
            desiredA,
            receivedBAmount,
            (desiredA * slippageRate) / 10_000,
            (receivedBAmount * slippageRate) / 10_000,
            msg.sender,
            block.timestamp + 10_000,
            feeType,
            isStable
        );

        address[] memory dustPath = new address[](2);
        dustPath[0] = tokenBAddress;
        dustPath[1] = tokenAAddress;

        uint256 swappedAmount;
        if (receivedBAmount > amountB) {
            swappedAmount = koiRouter.swapExactTokensForTokens(
                receivedBAmount - amountB,
                0,
                dustPath,
                msg.sender,
                block.timestamp + 10_000,
                isStableArr
            )[1];
        }

        tokenA.safeTransfer(msg.sender, desiredA - amountA + swappedAmount);
        tokenA.safeApprove(address(koiRouter), 0);
    }

    /**
     * @notice Withdraw tokenA from the tokenA and tokenB pair for the LP token
     *
     * @param tokenAAddress address - Withdrawing token address in the pair
     * @param tokenBAddress address - Side token address in the pair
     * @param lpTokenAmount uint256 - LP token amount to withdraw
     * @param isStable bool         - Stable pair or not
     * @param slippageRate  uint256 - Slippage rate over 10_000
     *
     * @dev Input 9_950 for slippage rate for 0,5% slippage
     */
    function withdraw(
        address tokenAAddress,
        address tokenBAddress,
        uint256 lpTokenAmount,
        bool isStable,
        uint256 slippageRate
    ) external override {
        address pairAddress = koiRouter.pairFor(tokenAAddress, tokenBAddress, isStable);

        IERC20 lpToken = IERC20(pairAddress);
        IERC20 tokenA = IERC20(tokenAAddress);
        IERC20 tokenB = IERC20(tokenBAddress);

        uint256 totalSupplyLP = lpToken.totalSupply();
        (uint256 tokenAReserve, uint256 tokenBReserve) = koiRouter.getReserves(
            tokenAAddress,
            tokenBAddress,
            isStable
        );

        uint256 amountADesired = (tokenAReserve * lpTokenAmount) / totalSupplyLP;
        uint256 amountBDesired = (tokenBReserve * lpTokenAmount) / totalSupplyLP;

        lpToken.safeTransferFrom(msg.sender, address(this), lpTokenAmount);
        lpToken.safeApprove(address(koiRouter), lpTokenAmount);

        (uint256 amountA, uint256 amountB) = koiRouter.removeLiquidity(
            tokenAAddress,
            tokenBAddress,
            lpTokenAmount,
            (amountADesired * slippageRate) / 10_000,
            (amountBDesired * slippageRate) / 10_000,
            address(this),
            block.timestamp + 10_000,
            isStable
        );

        address[] memory swapPath = new address[](2);
        swapPath[0] = tokenBAddress;
        swapPath[1] = tokenAAddress;

        bool[] memory isStableArr = new bool[](1);
        isStableArr[0] = isStable;

        tokenB.safeApprove(address(koiRouter), amountB);

        koiRouter.swapExactTokensForTokens(
            amountB,
            0, // TODO: set minimum amount for slippage
            swapPath,
            msg.sender,
            block.timestamp + 10_000,
            isStableArr
        );

        tokenA.safeTransfer(msg.sender, amountA);
    }

    /**
     * @notice Withdraw token from the contract for the emergency cases
     *
     * @param token address  - Token address to withdraw
     * @param amount uint256 - Amount to withdraw
     *
     * @dev Not a real case, so everyone can withdraw
     */
    function withdrawToken(address token, uint256 amount) external {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Calculate desired token amounts for the LP token considering the reserves
     *
     * @param tokenAmount uint256 - Depositing token amount
     * @param reserveA uint256    - tokenA reserve amount
     * @param reserveB uint256    - tokenB reserve amount
     * @return desiredA uint256 - Desired tokenA return amount
     * @return desiredB uint256 - Desired tokenB return amount
     * TODO: Modify to work with tokens with different decimals
     */
    function desiredAmounts(
        uint256 tokenAmount,
        uint256 reserveA,
        uint256 reserveB
    ) private pure returns (uint256 desiredA, uint256 desiredB) {
        uint256 total = reserveA + reserveB;

        desiredA = (tokenAmount * reserveA) / total;
        desiredB = tokenAmount - desiredA;

        return (desiredA, desiredB);
    }
}
