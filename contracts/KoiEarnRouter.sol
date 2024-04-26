// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

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

interface IKoiLP {}

contract KoiEarnRouter {
    using SafeERC20 for IERC20Metadata;

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
    ) external {
        IERC20Metadata tokenA = IERC20Metadata(tokenAAddress);
        IERC20Metadata tokenB = IERC20Metadata(tokenBAddress);

        tokenA.safeTransferFrom(msg.sender, address(this), tokenAmount);

        (uint256 tokenAReserve, uint256 tokenBReserve) = koiRouter.getReserves(
            tokenAAddress,
            tokenBAddress,
            isStable
        );

        (uint256 desiredA, uint256 desiredB) = desiredAmounts(
            tokenAmount,
            tokenAReserve,
            tokenBReserve,
            tokenA.decimals(),
            tokenB.decimals()
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

        uint256 swappedAmount = koiRouter.swapExactTokensForTokens(
            receivedBAmount - amountB,
            0,
            dustPath,
            msg.sender,
            block.timestamp + 10_000,
            isStableArr
        )[1];

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
    ) external {
        address pairAddress = koiRouter.pairFor(tokenAAddress, tokenBAddress, isStable);

        IERC20Metadata lpToken = IERC20Metadata(pairAddress);
        IERC20Metadata tokenA = IERC20Metadata(tokenAAddress);
        IERC20Metadata tokenB = IERC20Metadata(tokenBAddress);

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

        uint256 swappedAmount = koiRouter.swapExactTokensForTokens(
            amountB,
            0,
            swapPath,
            msg.sender,
            block.timestamp + 10_000,
            isStableArr
        )[1];

        tokenA.safeTransfer(msg.sender, amountA + swappedAmount);
    }

    /**
     *
     * @param tokenAmount uint256 - LP token amount
     * @param reserveA uint256    - tokenA reserve amount
     * @param reserveB uint256    - tokenB reserve amount
     * @param decimalA uint8      - tokenA decimals
     * @param decimalB uint8      - tokenB decimals
     * @return desiredA uint256 - Desired tokenA return amount
     * @return desiredB uint256 - Desired tokenB return amount
     */
    function desiredAmounts(
        uint256 tokenAmount,
        uint256 reserveA,
        uint256 reserveB,
        uint8 decimalA,
        uint8 decimalB
    ) private pure returns (uint256 desiredA, uint256 desiredB) {
        uint256 total = reserveA * uint256(decimalB) + reserveB * uint256(decimalA);

        desiredA = (tokenAmount * reserveA * decimalB) / total;
        desiredB = ((tokenAmount - desiredA) * decimalB) / decimalA;

        return (desiredA, desiredB);
    }
}
