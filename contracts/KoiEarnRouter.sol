// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface KOISwitchERC20Dynamic is IERC20 {
    function index0(address recipient) external view returns (uint);

    function index1(address recipient) external view returns (uint);

    function supplyIndex0(address recipient) external view returns (uint);

    function supplyIndex1(address recipient) external view returns (uint);
}

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

    function claimFeesView(
        address recipient,
        address tokenA,
        address tokenB,
        bool isStable
    ) external view returns (uint256 claimed0, uint256 claimed1);
}

interface IKoiEarnRouter {
    function deposit(
        address tokenAAddress,
        address tokenBAddress,
        uint256 tokenAmount,
        uint256 feeType,
        bool isStable,
        uint256 minDesiredA,
        uint256 minDesiredB
    ) external;

    function withdraw(
        address tokenAAddress,
        address tokenBAddress,
        uint256 lpTokenAmount,
        bool isStable,
        uint256 minimumAmount
    ) external;

    function claimFeesView(address recipient) external view returns (uint claimed0, uint claimed1);
}

interface IKoiPair is IERC20 {
    function index0() external view returns (uint256);

    function index1() external view returns (uint256);

    function supplyIndex0(address recipient) external view returns (uint256);

    function supplyIndex1(address recipient) external view returns (uint256);

    function claimable0(address recipient) external view returns (uint256);

    function claimable1(address recipient) external view returns (uint256);
}

/**
 * @title KoiEarnRouter
 * @author https://getclave.io
 */
contract KoiEarnRouter is IKoiEarnRouter {
    using SafeERC20 for IERC20;
    using SafeERC20 for IKoiPair;

    IKoiRouter private koiRouter;

    error INSUFFICIENT_AMOUNT();

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
     * @notice View claimable fees for tokenA and tokenB pair
     *
     * @dev Copied and modified from this source, as it has bug
     * https://github.com/muteio/switch-core/blob/4f08af924c60b8d0a8037997988bf2f71d72d264/contracts/dynamic/MuteSwitchPairDynamic.sol#L469
     */
    function claimFeesView(
        address recipient,
        address tokenA,
        address tokenB,
        bool isStable
    ) external view returns (uint256 claimed0, uint256 claimed1) {
        address pairAddress = koiRouter.pairFor(tokenA, tokenB, isStable);
        IKoiPair pair = IKoiPair(pairAddress);

        uint _supplied = pair.balanceOf(recipient); // get LP balance of `recipient`
        if (_supplied > 0) {
            uint _supplyIndex0 = pair.supplyIndex0(recipient); // get last adjusted index0 for recipient
            uint _supplyIndex1 = pair.supplyIndex1(recipient);
            uint _index0 = pair.index0(); // get global index0 for accumulated fees
            uint _index1 = pair.index1();
            uint _delta0 = _index0 - _supplyIndex0; // see if there is any difference that need to be accrued
            uint _delta1 = _index1 - _supplyIndex1;
            if (_delta0 > 0) {
                uint _share = (_supplied * _delta0) / 1e18; // add accrued difference for each supplied token
                claimed0 = pair.claimable0(recipient) + _share;
            }
            if (_delta1 > 0) {
                uint _share = (_supplied * _delta1) / 1e18;
                claimed1 = pair.claimable1(recipient) + _share;
            }
        }
    }

    /**
     * @notice Deposit tokenA for the tokenA and tokenB to the pair
     *
     * @param tokenAAddress address      - Depositing token address in the pair
     * @param tokenBAddress address      - Side token address in the pair
     * @param tokenAmount uint256        - Depositing token amount
     * @param isStable bool              - Stable pair or not
     * @param minDesiredA uint256        - Minimum desired tokenA amount
     * @param minDesiredB uint256        - Minimum desired tokenB amount
     *
     * @dev Input 9_950 for slippage rate for 0,5% slippage
     */
    function deposit(
        address tokenAAddress,
        address tokenBAddress,
        uint256 tokenAmount,
        uint256 feeType,
        bool isStable,
        uint256 minDesiredA,
        uint256 minDesiredB
    ) external override {
        IERC20 tokenA = IERC20(tokenAAddress);
        IERC20 tokenB = IERC20(tokenBAddress);

        tokenA.safeTransferFrom(msg.sender, address(this), tokenAmount);

        (uint256 tokenAReserve, uint256 tokenBReserve) = koiRouter.getReserves(
            tokenAAddress,
            tokenBAddress,
            isStable
        );

        (uint256 desiredA, ) = desiredAmounts(tokenAmount, tokenAReserve, tokenBReserve);

        tokenA.safeApprove(address(koiRouter), tokenAmount);

        address[] memory swapPath = new address[](2);
        swapPath[0] = tokenAAddress;
        swapPath[1] = tokenBAddress;

        bool[] memory isStableArr = new bool[](1);
        isStableArr[0] = isStable;

        uint256 receivedBAmount = koiRouter.swapExactTokensForTokens(
            tokenAmount - desiredA,
            minDesiredB,
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
            minDesiredA,
            minDesiredB,
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

        tokenA.safeTransfer(msg.sender, desiredA - amountA);
        tokenA.safeApprove(address(koiRouter), 0);
    }

    /**
     * @notice Withdraw tokenA from the tokenA and tokenB pair for the LP token
     *
     * @param tokenAAddress address - Withdrawing token address in the pair
     * @param tokenBAddress address - Side token address in the pair
     * @param lpTokenAmount uint256 - LP token amount to withdraw
     * @param isStable bool         - Stable pair or not
     * @param minimumAmount uint256 - Minimum amount to withdraw
     *
     * @dev Input 9_950 for slippage rate for 0,5% slippage
     */
    function withdraw(
        address tokenAAddress,
        address tokenBAddress,
        uint256 lpTokenAmount,
        bool isStable,
        uint256 minimumAmount
    ) external override {
        address pairAddress = koiRouter.pairFor(tokenAAddress, tokenBAddress, isStable);

        IKoiPair lpToken = IKoiPair(pairAddress);
        IERC20 tokenA = IERC20(tokenAAddress);
        IERC20 tokenB = IERC20(tokenBAddress);

        lpToken.safeTransferFrom(msg.sender, address(this), lpTokenAmount);
        lpToken.safeApprove(address(koiRouter), lpTokenAmount);

        (uint256 amountA, uint256 amountB) = koiRouter.removeLiquidity(
            tokenAAddress,
            tokenBAddress,
            lpTokenAmount,
            0,
            0,
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

        tokenA.safeTransfer(msg.sender, amountA);

        if (amountA + swappedAmount < minimumAmount) {
            revert INSUFFICIENT_AMOUNT();
        }
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

    /**
     * @notice Calculate claimable fees amount

     * @param recipient address - Recipient address
     * @return claimed0 uint256 - Claimable tokenA amount
     * @return claimed1 uint256 - Claimable tokenB amount
     */
    function claimFeesView(address recipient) external view returns (uint claimed0, uint claimed1) {
        address pairAddress = koiRouter.pairFor(tokenAAddress, tokenBAddress, isStable);

        IERC20 lpToken = KOISwitchERC20Dynamic(pairAddress);

          uint _supplied = lpToken.balanceOf[recipient];
        if (_supplied > 0) {
            uint _supplyIndex0 = lpToken.supplyIndex0[recipient];
            uint _supplyIndex1 = lpToken.supplyIndex1[recipient];
            uint _index0 = lpToken.index0;
            uint _index1 = lpToken.index1;
            uint _delta0 = _index0 - _supplyIndex0;
            uint _delta1 = _index1 - _supplyIndex1;
            if (_delta0 > 0) {
                uint _share = _supplied * _delta0 / 1e18;
                claimed0 = claimable0[recipient] + _share;
            }
            if (_delta1 > 0) {
                uint _share = _supplied * _delta1 / 1e18;
                claimed1 = claimable1[recipient] + _share;
            }
        }
    }
}
