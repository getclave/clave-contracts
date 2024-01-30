// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IPaymaster, ExecutionResult, PAYMASTER_VALIDATION_SUCCESS_MAGIC} from '@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymaster.sol';
import {IPaymasterFlow} from '@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymasterFlow.sol';
import {Transaction} from '@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol';
import {BOOTLOADER_FORMAL_ADDRESS} from '@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {PrimaryProdDataServiceConsumerBase} from '@redstone-finance/evm-connector/contracts/data-services/PrimaryProdDataServiceConsumerBase.sol';
import {Errors} from '../libraries/Errors.sol';
import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {BootloaderAuth} from '../auth/BootloaderAuth.sol';
import {IClaveRegistry} from '../interfaces/IClaveRegistry.sol';

// Allowed ERC-20 tokens data struct input
struct TokenInput {
    address tokenAddress; // token addresses
    uint32 decimals; // decimals of the tokens
    uint256 priceMarkup; // price markup percentage
}

// Stored token data including oracle ids and price markups
struct TokenData {
    uint32 decimals; // decimals of the tokens
    uint192 markup; // price markup percentage
}

/**
 * @title SubsidizerPaymaster is a super of the ERC20Paymaster to pay for transaction fees in allowed ERC-20 tokens (stablecoins) by subsidizing a specific amount
 * @author https://getclave.io
 * @dev This contract uses Redstone oracle to get token prices, please check [Redstone docs](https://docs.redstone.finance/docs/smart-contract-devs/get-started/redstone-core).
 */
contract SubsidizerPaymasterMock is
    IPaymaster,
    PrimaryProdDataServiceConsumerBase,
    Ownable,
    BootloaderAuth
{
    // Using OpenZeppelin's SafeERC20 library to perform token transfers
    using SafeERC20 for IERC20;

    // The nominator used for price calculation
    uint256 constant PRICE_PAIR_NOMINATOR = 1e18;
    // The nominator used for markup calculation
    uint256 constant MARKUP_NOMINATOR = 1e6;
    //The nominator used to get rid of oracle price decimals
    uint256 constant ORACLE_NOMINATOR = 1e8;
    // Maximum subsidized fee amount
    uint256 constant MAX_GAS_TO_SUBSIDIZE = 1_250_000;

    // Clave account registry contract
    address public claveRegistry;

    // Store allowed tokens addresses with their data
    mapping(address => TokenData) public allowedTokens;

    // Event to be emitted when a token is used to pay for transaction
    event SubsidizerPaymasterUsed(address indexed user, address token);
    // Event to be emitted when a new token is allowed
    event ERC20TokenAllowed(address token);
    // Event to be emitted when a new token is removed
    event ERC20TokenRemoved(address token);
    // Event to be emitted when the balance is withdrawn
    event BalanceWithdrawn(address to, uint256 amount);

    /**
     * @notice Constructor function
     * @param tokens TokenInput[] - Array of token addresses, markups, and their oracle ids in string
     * @dev Use markup by adding percentage amount to 100, e.g. 10% markup will be 11000
     * @dev Make sure to use true decimal values for the tokens, otherwise the conversions will be incorrect
     */
    constructor(TokenInput[] memory tokens, address registry) {
        for (uint256 i = 0; i < tokens.length; i++) {
            // Decline zero-addresses
            if (tokens[i].tokenAddress == address(0)) revert Errors.INVALID_TOKEN();

            // Decline false markup values
            if (tokens[i].priceMarkup < 5000 || tokens[i].priceMarkup >= 100000)
                revert Errors.INVALID_TOKEN();
            uint192 priceMarkup = uint192(tokens[i].priceMarkup * (MARKUP_NOMINATOR / 1e4));

            allowedTokens[tokens[i].tokenAddress] = TokenData(tokens[i].decimals, priceMarkup);
        }

        claveRegistry = registry;
    }

    // Allow receiving ETH
    receive() external payable {}

    /// @inheritdoc IPaymaster
    /// @dev return the fee payer token address in the context
    function validateAndPayForPaymasterTransaction(
        bytes32 /**_txHash*/,
        bytes32 /**_suggestedSignedHash*/,
        Transaction calldata _transaction
    ) external payable onlyBootloader returns (bytes4 magic, bytes memory context) {
        // By default we consider the transaction as accepted.
        magic = PAYMASTER_VALIDATION_SUCCESS_MAGIC;

        // Get the user address
        address userAddress = address(uint160(_transaction.from));

        // Check if the account is a Clave account
        if (!IClaveRegistry(claveRegistry).isClave(userAddress)) revert Errors.NOT_CLAVE_ACCOUNT();

        // Revert if standart paymaster input is shorter than 4 bytes
        if (_transaction.paymasterInput.length < 4) revert Errors.SHORT_PAYMASTER_INPUT();

        // Check the paymaster input selector to detect flow
        bytes4 paymasterInputSelector = bytes4(_transaction.paymasterInput[0:4]);
        if (paymasterInputSelector != IPaymasterFlow.approvalBased.selector)
            revert Errors.UNSUPPORTED_FLOW();

        // Extract token address and oracle payload from the paymaster input and check if it is allowed
        (address token, , bytes memory oracleCalldata) = abi.decode(
            _transaction.paymasterInput[4:],
            (address, uint256, bytes)
        );
        if (allowedTokens[token].decimals == uint32(0)) revert Errors.UNSUPPORTED_TOKEN();

        address thisAddress = address(this);
        uint256 providedAllowance = IERC20(token).allowance(userAddress, thisAddress);

        // Required ETH to pay fees
        uint256 requiredETH = _transaction.gasLimit * _transaction.maxFeePerGas;
        // Required ETH to receive from the user
        uint256 userToPayETH;
        if (_transaction.gasLimit > MAX_GAS_TO_SUBSIDIZE) {
            userToPayETH =
                (_transaction.gasLimit - MAX_GAS_TO_SUBSIDIZE) *
                _transaction.maxFeePerGas;
        } else {
            userToPayETH = 0;
        }

        // Conversion rate of ETH to token
        // 0, if not receiving tokens from user
        uint256 rate;

        if (userToPayETH > 0) {
            rate = getPairPrice(token, oracleCalldata);
            // Calculated fee amount as token
            uint256 requiredToken = (userToPayETH * rate) / PRICE_PAIR_NOMINATOR;

            // Check token allowance for the fee
            if (providedAllowance < requiredToken) revert Errors.LESS_ALLOWANCE_FOR_PAYMASTER();

            // Transfer token to the fee collector
            IERC20(token).safeTransferFrom(userAddress, address(this), requiredToken);
        }

        // Transfer fees to the bootloader
        (bool feeSuccess, ) = payable(BOOTLOADER_FORMAL_ADDRESS).call{value: requiredETH}('');
        if (!feeSuccess) revert Errors.FAILED_FEE_TRANSFER();

        // Use fee token address as context
        context = abi.encode(token, rate);
    }

    /// @inheritdoc IPaymaster
    function postTransaction(
        bytes calldata _context,
        Transaction calldata _transaction,
        bytes32 /**_txHash*/,
        bytes32 /**_suggestedSignedHash*/,
        ExecutionResult /**_txResult*/,
        uint256 _maxRefundedGas
    ) external payable onlyBootloader {
        (address tokenAddress, uint256 rate) = abi.decode(_context, (address, uint256));
        address fromAddress = address(uint160(_transaction.from));

        uint256 refundAmount = calcRefundAmount(
            _transaction.gasLimit,
            _maxRefundedGas,
            _transaction.maxFeePerGas,
            rate
        );

        if (refundAmount > 0) IERC20(tokenAddress).safeTransfer(fromAddress, refundAmount);

        // Emit user address with fee payer token
        emit SubsidizerPaymasterUsed(fromAddress, tokenAddress);
    }

    /**
     * @notice Allow a new token to be used in paymaster
     * @param token TokenInput calldata - Token address and its oracle ids in string of allowed token
     * @dev Only owner address can call this method
     * @dev Make sure to use true decimal values for the tokens, otherwise the conversions will be incorrect
     */
    function allowToken(TokenInput calldata token) external onlyOwner {
        // Skip zero-addresses
        if (token.tokenAddress == address(0)) {
            revert Errors.INVALID_TOKEN();
        }

        // Skip false markup values
        if (token.priceMarkup < 5000 || token.priceMarkup >= 100000) revert Errors.INVALID_MARKUP();
        uint192 priceMarkup = uint192(token.priceMarkup * (MARKUP_NOMINATOR / 1e4));

        allowedTokens[token.tokenAddress] = TokenData(token.decimals, uint192(priceMarkup));
        emit ERC20TokenAllowed(token.tokenAddress);
    }

    /**
     * @notice Remove allowed paymaster tokens
     * @param tokenAddress address - Token address to be removed
     * @dev Only owner address can call this method
     */
    function removeToken(address tokenAddress) external onlyOwner {
        delete allowedTokens[tokenAddress];
        emit ERC20TokenRemoved(tokenAddress);
    }

    /**
     * @notice Withdraw paymaster funds as owner
     * @param to address     - Token receiver address
     * @param amount uint256 - Amount to be withdrawn
     * @dev Only owner address can call this method
     */
    function withdraw(address to, uint256 amount) external onlyOwner {
        // Send paymaster funds to the given address
        (bool success, ) = payable(to).call{value: amount}('');
        if (!success) revert Errors.UNAUTHORIZED_WITHDRAW();

        emit BalanceWithdrawn(to, amount);
    }

    /**
     * @notice Withdraw paymaster token funds as owner
     * @param token address  - Token address to withdraw
     * @param to    address  - Token receiver address
     * @param amount uint256 - Amount to be withdrawn
     * @dev Only owner address can call this method
     */
    function withdrawToken(address token, address to, uint256 amount) external onlyOwner {
        // Send paymaster funds to the given address
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @notice This function calls the oracle and returns the values
     * @param - bytes - Oracle manuel payload
     * @return uint256 - Oracle return as token price
     * @dev bytes parameter is extracted from the paymaster input by the oracle contract, so it is NOT UNUSED here
     * @dev This function should be called by an external call inside this contract to pass its specific calldata
     */
    function callOracle(
        bytes memory //* oracleCalldata */
    ) external view returns (uint256) {
        // return getOracleNumericValueFromTxMsg(bytes32('ETH'));
        return 1500 * ORACLE_NOMINATOR;
    }

    /**
     * @notice This function gets the ETH/PARAM_TOKEN price from the oracle
     * @param token address        - Token address
     * @param oracleCalldata bytes - Oracle calldata for Redstone
     * @return rate uint256 - ETH/TOKEN price
     * @dev TOKEN price is accepted as 1 $
     */
    function getPairPrice(
        address token,
        bytes memory oracleCalldata
    ) public view returns (uint256 rate) {
        // Used asset decimals
        uint256 tokenDecimals = 10 ** (allowedTokens[token].decimals);
        // Oracle value
        uint256 value = this.callOracle(oracleCalldata);

        // Calculated token price
        rate =
            (value * allowedTokens[token].markup * tokenDecimals) /
            (ORACLE_NOMINATOR * MARKUP_NOMINATOR);
    }

    /**
     * @notice This function calculates the gas refund amount for the user
     * @param gasLimit uint256     - Gas limit of the transaction
     * @param gasRefunded uint256  - Unused gas amount
     * @param maxFeePerGas uint256 - Gas price from zkSync transaction
     * @param rate uint256         - Conversion rate regarding to ETH/Token pair
     * @return refundTokenAmount uint256 - Refund amount as token
     */
    function calcRefundAmount(
        uint256 gasLimit,
        uint256 gasRefunded,
        uint256 maxFeePerGas,
        uint256 rate
    ) public pure returns (uint256 refundTokenAmount) {
        if (!(rate > 0)) return refundTokenAmount;

        if (gasLimit > MAX_GAS_TO_SUBSIDIZE) {
            uint256 userPaidGas = gasLimit - MAX_GAS_TO_SUBSIDIZE;
            uint256 gasUsed = gasLimit - gasRefunded;

            // If, gasUsed is less than we want to pay, compensate user
            // Else, we can pay (userPaidGas - (gasUsed - MAX_FEE_TO_SUBSIDIZE)) at best, which can
            // be simplified to _maxRefundedGas
            uint256 refundGas = MAX_GAS_TO_SUBSIDIZE > gasUsed ? userPaidGas : gasRefunded;

            refundTokenAmount = (refundGas * maxFeePerGas * rate) / PRICE_PAIR_NOMINATOR;
        }
    }
}
