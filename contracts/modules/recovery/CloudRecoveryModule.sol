// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {SignatureChecker} from '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';

import {EIP712} from '../../helpers/EIP712.sol';
import {Errors} from '../../libraries/Errors.sol';
import {IInitable} from '../../interfaces/IInitable.sol';
import {IClaveAccount} from '../../interfaces/IClave.sol';
import {BaseRecovery} from './base/BaseRecovery.sol';

/**
 * @title Cloud Account Recovery Module
 * @notice Recovers the account using a key stored in iCloud or similar
 * @author https://getclave.io
 */
contract CloudRecoveryModule is BaseRecovery {
    // Signature verification helper library
    using SignatureChecker for address;

    // Timelock duration for the recovery process
    uint256 public immutable TIMELOCK;

    // Cloud guardian addresses for each account
    mapping(address => address) cloudGuardian;

    /**
     * @notice Emitted when a new cloud guardian is set for an account
     * @param account address  - Account the guardian was set for
     * @param guardian address - Address of the new guardian
     */
    event UpdateGuardian(address indexed account, address indexed guardian);

    /**
     * @notice Constructor function of the module
     * @param name string memory    - eip712 name
     * @param version string memory - eip712 version
     * @param timelock uint256      - timelock amount for recovery processes
     */
    constructor(string memory name, string memory version, uint256 timelock) EIP712(name, version) {
        TIMELOCK = timelock;
    }

    /**
     * @notice Initialize the module for the calling account with the given guardian
     * @dev Module must not be already inited for the account
     * @param initData bytes calldata - abi encoded address of the guardian
     */
    function init(bytes calldata initData) external override {
        if (isInited(msg.sender)) {
            revert Errors.ALREADY_INITED();
        }

        if (!IClaveAccount(msg.sender).isModule(address(this))) {
            revert Errors.MODULE_NOT_ADDED_CORRECTLY();
        }

        address guardian = abi.decode(initData, (address));

        emit Inited(msg.sender);

        _updateGuardian(guardian);
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

        delete cloudGuardian[msg.sender];

        emit Disabled(msg.sender);

        _stopRecovery();
    }

    /**
     * @notice Update the guardian for the calling account
     * @dev Recovery must not be in progress for the account
     * @dev Module must be inited for the account
     * @dev Guardian must not be the zero address
     * @param guardian address - Address of the new guardian
     */
    function updateGuardian(address guardian) external {
        if (!isInited(msg.sender)) {
            revert Errors.RECOVERY_NOT_INITED();
        }

        if (isRecovering(msg.sender)) {
            revert Errors.RECOVERY_IN_PROGRESS();
        }

        _updateGuardian(guardian);
    }

    /**
     * @notice Starts a recovery process for the given account
     * @dev Module must be inited for the account
     * @dev Account must not have a recovery in progress
     * @param recoveryData RecoveryData calldata - Data for the recovery process
     * @param signature bytes calldata           - Signature of the cloud guardian
     */
    function startRecovery(RecoveryData calldata recoveryData, bytes calldata signature) external {
        // Get the recovery address
        address recoveringAddress = recoveryData.recoveringAddress;

        // Check if the nonce is correct
        if (recoveryData.nonce != recoveryNonces[recoveringAddress]) {
            revert Errors.INVALID_RECOVERY_NONCE();
        }

        // Check if an account is already on recovery progress
        if (isRecovering(recoveringAddress)) {
            revert Errors.RECOVERY_IN_PROGRESS();
        }

        // Check if the account recovery is inited
        if (!isInited(recoveringAddress)) {
            revert Errors.RECOVERY_NOT_INITED();
        }

        bytes32 eip712Hash = _hashTypedDataV4(_recoveryDataHash(recoveryData));
        address guardian = cloudGuardian[recoveringAddress];

        if (!guardian.isValidSignatureNow(eip712Hash, signature)) {
            revert Errors.INVALID_GUARDIAN_SIGNATURE();
        }

        // Create recovery state
        recoveryStates[recoveryData.recoveringAddress] = RecoveryState({
            timelockExpiry: block.timestamp + TIMELOCK,
            newOwner: recoveryData.newOwner
        });

        recoveryNonces[recoveringAddress]++;

        emit RecoveryStarted(
            recoveryData.recoveringAddress,
            recoveryData.newOwner,
            block.timestamp + TIMELOCK
        );
    }

    /**
     * @notice Get the guardian for the given account
     * @param account address - Address of the account
     */
    function getGuardian(address account) external view returns (address) {
        return cloudGuardian[account];
    }

    /// @inheritdoc BaseRecovery
    function isInited(address account) public view override returns (bool) {
        return cloudGuardian[account] != address(0);
    }

    function _updateGuardian(address guardian) internal {
        if (guardian == address(0)) {
            revert Errors.ZERO_ADDRESS_GUARDIAN();
        }

        cloudGuardian[msg.sender] = guardian;

        emit UpdateGuardian(msg.sender, guardian);
    }
}
