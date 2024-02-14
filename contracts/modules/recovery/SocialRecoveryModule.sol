// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {SignatureChecker} from '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';

import {EIP712} from '../../helpers/EIP712.sol';
import {Errors} from '../../libraries/Errors.sol';
import {IClaveAccount} from '../../interfaces/IClave.sol';
import {BaseRecovery} from './base/BaseRecovery.sol';

/**
 * @title Social Account Recovery Module
 * @notice Recovers the account using signatures from friends or family members
 * @author https://getclave.io
 */
contract SocialRecoveryModule is BaseRecovery {
    // Signature verification helper library
    using SignatureChecker for address;

    // Accounts recovery config states
    struct RecoveryConfig {
        uint128 timelock; // Recovery timelock duration
        uint128 threshold; // Recovery threshold
        address[] guardians; // Guardian addresses
    }

    // Prepared guardian data for the recoveries
    struct GuardianData {
        address guardian; // Guardian address
        bytes signature; // Guardian signature
    }

    uint128 public immutable MIN_TIMELOCK;
    uint128 public immutable MIN_THRESHOLD;

    mapping(address => RecoveryConfig) recoveryConfigs;

    event UpdateConfig(address indexed account, RecoveryConfig config);

    /**
     *
     * @param name string memory    - eip712uint 128  -  name
     * @param version string memory - eip712 version
     * @param minTimelock uint 128  - minimum timelock for recovery configs
     * @param minThreshold uint128  - minimum threshold for recovery configs
     */
    constructor(
        string memory name,
        string memory version,
        uint128 minTimelock,
        uint128 minThreshold
    ) EIP712(name, version) {
        MIN_TIMELOCK = minTimelock;
        MIN_THRESHOLD = minThreshold;
    }

    /**
     * @notice Initialize the module for the calling account with the given config
     * @dev Module must not be already inited for the account
     * @param initData bytes calldata - abi encoded RecoveryConfig
     */
    function init(bytes calldata initData) external override {
        if (isInited(msg.sender)) {
            revert Errors.ALREADY_INITED();
        }

        if (!IClaveAccount(msg.sender).isModule(address(this))) {
            revert Errors.MODULE_NOT_ADDED_CORRECTLY();
        }

        RecoveryConfig memory config = abi.decode(initData, (RecoveryConfig));

        emit Inited(msg.sender);

        _updateConfig(config);
    }

    /**
     * @notice Disable the module for the calling account
     * @dev Stops any recovery in progress
     */
    function disable() external override {
        if (!isInited(msg.sender)) {
            revert Errors.RECOVERY_NOT_INITED();
        }

        if (IClaveAccount(msg.sender).isModule(address(this))) {
            revert Errors.MODULE_NOT_REMOVED_CORRECTLY();
        }

        delete recoveryConfigs[msg.sender];

        emit Disabled(msg.sender);

        _stopRecovery();
    }

    /**
     * @notice Set a new config for the calling account
     * @dev Module must be inited for the account
     * @dev Account must not have a recovery in progress
     * @param config RecoveryConfig memory - new recovery config
     */
    function updateConfig(RecoveryConfig memory config) external {
        if (!isInited(msg.sender)) {
            revert Errors.RECOVERY_NOT_INITED();
        }

        if (isRecovering(msg.sender)) {
            revert Errors.RECOVERY_IN_PROGRESS();
        }

        _updateConfig(config);
    }

    /**
     * @notice Starts a recovery process for the given account
     * @dev Module must be inited for the account
     * @dev Account must not have a recovery in progress
     * @dev Checks the validity of the guardians and their signatures
     * @param recoveryData RecoveryData calldata   - Data for the recovery process
     * @param guardianData GuardianData[] calldata - Guardian addresses and their signatures
     */
    function startRecovery(
        RecoveryData calldata recoveryData,
        GuardianData[] calldata guardianData
    ) external {
        // Get the recovery address
        address recoveringAddress = recoveryData.recoveringAddress;

        // Check if an account is already on recovery progress
        if (isRecovering(recoveringAddress)) {
            revert Errors.RECOVERY_IN_PROGRESS();
        }

        // Check if the account recovery is inited
        if (!isInited(recoveringAddress)) {
            revert Errors.RECOVERY_NOT_INITED();
        }

        RecoveryConfig memory config = recoveryConfigs[recoveringAddress];

        // Check if the nonce is correct
        if (recoveryData.nonce != recoveryNonces[recoveringAddress]) {
            revert Errors.INVALID_RECOVERY_NONCE();
        }

        bytes32 eip712Hash = _hashTypedDataV4(_recoveryDataHash(recoveryData));

        // Check guardian data

        uint256 validGuardians = 0;
        address lastGuardian;
        for (uint256 i = 0; i < guardianData.length; ) {
            GuardianData memory data = guardianData[i];
            address guardian = data.guardian;

            if (guardian <= lastGuardian) {
                revert Errors.GUARDIANS_MUST_BE_SORTED();
            }

            lastGuardian = guardian;

            bool isGuardian;
            for (uint256 j = 0; j < config.guardians.length; ) {
                if (guardian == config.guardians[j]) {
                    isGuardian = true;
                    break;
                }

                unchecked {
                    j++;
                }
            }

            if (!isGuardian) {
                revert Errors.INVALID_GUARDIAN();
            }

            if (guardian.isValidSignatureNow(eip712Hash, data.signature)) {
                validGuardians++;
            }

            unchecked {
                i++;
            }
        }

        // Check recovering guardian amount
        if (validGuardians < config.threshold) {
            revert Errors.INSUFFICIENT_GUARDIANS();
        }

        // Create recovery state
        recoveryStates[recoveringAddress] = RecoveryState(
            block.timestamp + config.timelock,
            recoveryData.newOwner
        );

        recoveryNonces[recoveringAddress]++;

        emit RecoveryStarted(
            recoveringAddress,
            recoveryData.newOwner,
            block.timestamp + config.timelock
        );
    }

    /**
     * @notice Get the configured timelock for an account
     * @param account address - Address of the account
     * @return timelock uint128 - Timelock duration
     */
    function getTimelock(address account) external view returns (uint128) {
        return recoveryConfigs[account].timelock;
    }

    /**
     * @notice Get the configured threshold for an account
     * @param account address - Address of the account
     * @return threshold uint128 - Threshold amount
     */
    function getThreshold(address account) external view returns (uint128) {
        return recoveryConfigs[account].threshold;
    }

    /**
     * @notice Get the configured guardians for an account
     * @param account address - Address of the account
     * @return guardians address[] - Guardian addresses
     */
    function getGuardians(address account) external view returns (address[] memory) {
        return recoveryConfigs[account].guardians;
    }

    /// @inheritdoc BaseRecovery
    function isInited(address account) public view override returns (bool) {
        return recoveryConfigs[account].timelock != 0;
    }

    function _updateConfig(RecoveryConfig memory config) internal {
        if (!_isValidConfig(config)) {
            revert Errors.INVALID_RECOVERY_CONFIG();
        }

        recoveryConfigs[msg.sender] = config;

        emit UpdateConfig(msg.sender, config);
    }

    function _isValidConfig(RecoveryConfig memory config) private view returns (bool) {
        return
            config.timelock > MIN_TIMELOCK &&
            config.threshold <= config.guardians.length &&
            config.threshold > MIN_THRESHOLD;
    }
}
