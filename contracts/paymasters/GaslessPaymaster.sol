// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import {IPaymaster, ExecutionResult, PAYMASTER_VALIDATION_SUCCESS_MAGIC} from '@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymaster.sol';
import {IPaymasterFlow} from '@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymasterFlow.sol';
import {Transaction} from '@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol';
import {BOOTLOADER_FORMAL_ADDRESS} from '@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Errors} from '../libraries/Errors.sol';
import {IClaveRegistry} from '../interfaces/IClaveRegistry.sol';
import {BootloaderAuth} from '../auth/BootloaderAuth.sol';

/**
 * @title GaslessPaymaster to pay for limited number of transactions' fees, also limitless tx for specified addresses
 * @author https://getclave.io
 */
contract GaslessPaymaster is IPaymaster, Ownable, BootloaderAuth {
    uint256 public maxSponsoredEth = 0.001 ether;
    // User tx limit per paymaster
    uint256 public userLimit;
    // Clave account registry contract
    address public claveRegistry;
    address public claveRegistry2;

    // Store users sponsored tx count
    mapping(address => uint256) public userSponsored;
    mapping(address => bool) public limitlessAddresses;

    // Event to be emitted when the balance is withdrawn
    event BalanceWithdrawn(address to, uint256 amount);
    // Event to be emitted when the user limit is updated
    event UserLimitChanged(uint256 newUserLimit);
    // Event to be emitted when a user tx is sponsored
    event FeeSponsored(address user);

    // Allow receiving ETH
    receive() external payable {}

    /**
     * @notice Constructor functino of the paymaster
     * @param registry address - Clave registry address
     * @param limit uint256    - User sponsorship limit
     */
    constructor(address registry, uint256 limit) Ownable(msg.sender) {
        claveRegistry = registry;
        userLimit = limit;
    }

    /// @inheritdoc IPaymaster
    function validateAndPayForPaymasterTransaction(
        bytes32 /**_txHash*/,
        bytes32 /**_suggestedSignedHash*/,
        Transaction calldata _transaction
    ) external payable onlyBootloader returns (bytes4 magic, bytes memory context) {
        // By default we consider the transaction as accepted.
        magic = PAYMASTER_VALIDATION_SUCCESS_MAGIC;

        // Revert if standart paymaster input is shorter than 4 bytes
        if (_transaction.paymasterInput.length < 4) revert Errors.SHORT_PAYMASTER_INPUT();

        // Check the paymaster input selector to detect flow
        bytes4 paymasterInputSelector = bytes4(_transaction.paymasterInput[0:4]);
        if (paymasterInputSelector != IPaymasterFlow.general.selector)
            revert Errors.UNSUPPORTED_FLOW();

        // Get the user address
        address userAddress = address(uint160(_transaction.from));

        if (limitlessAddresses[userAddress]) {
            // Allow limitlessAddresses to use paymaster freely
        } else if (
            IClaveRegistry(claveRegistry).isClave(userAddress) ||
            IClaveRegistry(claveRegistry2).isClave(userAddress)
        ) {
            // Check if the account is a Clave account
            // Then, check the user sponsorship limit and decrease
            uint256 txAmount = userSponsored[userAddress];
            if (txAmount >= userLimit) revert Errors.USER_LIMIT_REACHED();
            userSponsored[userAddress]++;
        } else {
            revert Errors.NOT_CLAVE_ACCOUNT();
        }

        // Required ETH and token to pay fees
        uint256 requiredETH = _transaction.gasLimit * _transaction.maxFeePerGas;

        // Check if the required ETH is less than the maximum sponsored ETH
        if (requiredETH > maxSponsoredEth) revert Errors.EXCEEDS_MAX_SPONSORED_ETH();

        // Transfer fees to the bootloader
        (bool success, ) = payable(BOOTLOADER_FORMAL_ADDRESS).call{value: requiredETH}('');
        if (!success) revert Errors.FAILED_FEE_TRANSFER();
    }

    /// @inheritdoc IPaymaster
    function postTransaction(
        bytes calldata /**_context*/,
        Transaction calldata _transaction,
        bytes32 /**_txHash*/,
        bytes32 /**_suggestedSignedHash*/,
        ExecutionResult /**_txResult*/,
        uint256 /**_maxRefundedGas*/
    ) external payable onlyBootloader {
        address userAddress = address(uint160(_transaction.from));

        emit FeeSponsored(userAddress);
    }

    /**
     * @notice Get remaining user tx limit
     * @param userAddress address - User address
     * @return uint256 - Remaining user tx limit
     */
    function getRemainingUserLimit(address userAddress) external view returns (uint256) {
        uint256 limit;
        uint256 sponsored = userSponsored[userAddress];

        limit = userLimit > sponsored ? (userLimit - sponsored) : 0;

        return limit;
    }

    /**
     * @notice Withdraw paymaster funds as owner
     * @param to address - Token receiver address
     * @param amount uint256 - Amount to be withdrawn
     * @dev Only owner address can call this method
     */
    function withdraw(address to, uint256 amount) external onlyOwner {
        // Send paymaster funds to the owner
        (bool success, ) = payable(to).call{value: amount}('');
        if (!success) revert Errors.UNAUTHORIZED_WITHDRAW();

        emit BalanceWithdrawn(to, amount);
    }

    /**
     * @notice Update user tx sponsorship limit
     * @param updatingUserLimit uint256 - New user free tx limit
     * @dev Only owner address can call this method
     */
    function updateUserLimit(uint256 updatingUserLimit) external onlyOwner {
        userLimit = updatingUserLimit;
        emit UserLimitChanged(updatingUserLimit);
    }

    /**
     * @notice Update the maximum sponsored ETH
     * @param newMaxSponsoredEth uint256 - New maximum sponsored ETH
     * @dev Only owner address can call this method
     */
    function updateMaxSponsoredEth(uint256 newMaxSponsoredEth) external onlyOwner {
        maxSponsoredEth = newMaxSponsoredEth;
    }

    /**
     * @notice Add minter addresses to the whitelist
     * @param addresses address[] - Array of addresses to be added
     * @dev Only owner address can call this method
     * @dev Given addresses should not be included in the list
     */
    function addLimitlessAddresses(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            require(addr != address(0) && !limitlessAddresses[addr]);

            limitlessAddresses[addr] = true;
        }
    }

    /**
     * @notice Remove minter addresses from the whitelist
     * @param addresses address[] - Array of addresses to be removed
     * @dev Only owner address can call this method
     * @dev Given addresses should be included in the list
     */
    function removeLimitlessAddresses(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            require(limitlessAddresses[addr]);

            delete (limitlessAddresses[addr]);
        }
    }

    /**
     * @notice Change the Clave registry address
     * @param newRegistry address - New Clave registry address
     * @dev Only owner address can call this method
     */
    function changeClaveRegistry(address newRegistry) external onlyOwner {
        claveRegistry = newRegistry;
    }

    /**
     * @notice Change the Clave registry2 address
     * @param newRegistry address - New Clave registry2 address
     * @dev Only owner address can call this method
     */
    function changeClaveRegistry2(address newRegistry) external onlyOwner {
        claveRegistry2 = newRegistry;
    }
}
