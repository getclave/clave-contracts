// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import {EIP712} from '../../../helpers/EIP712.sol';
import {IModule} from '../../../interfaces/IModule.sol';
import {Errors} from '../../../libraries/Errors.sol';
import {IClaveAccount} from '../../../interfaces/IClave.sol';

/**
 * @title Base Account Recovery Module
 * @notice Base contract for account recovery modules
 * @author https://getclave.io
 * @dev This contract is abstract and needs to be inherited to implement the recovery logic
 */
abstract contract BaseRecovery is IModule, EIP712 {
    // Recovery states of the accounts
    struct RecoveryState {
        uint256 timelockExpiry; // Expiry date of the recovery timelock
        bytes newOwner; // New owner of the account
    }

    // Recovery data config
    struct RecoveryData {
        address recoveringAddress; //  Address of the account to recover
        bytes newOwner; //  New owner of the account
        uint256 nonce; //  Nonce of the recovery data
    }

    // eip 712 typehash
    bytes32 constant _RECOVERY_DATA_TYPEHASH =
        keccak256('RecoveryData(address recoveringAddress,bytes newOwner,uint256 nonce)');

    // States of the accounts to be recovered
    mapping(address => RecoveryState) public recoveryStates;
    // Nonces of the account recovery operations
    mapping(address => uint256) public recoveryNonces;

    /**
     * @notice Emitted when a recovery process starts for an account
     * @param account address        - Recovering account
     * @param newOwner bytes         - New owner of the account
     * @param timelockExpiry uint256 - Expiry date of the recovery timelock
     */
    event RecoveryStarted(address indexed account, bytes newOwner, uint256 timelockExpiry);
    /**
     * @notice Emitted when an account stops it's recovery process
     * @param account address - Account the recovery process was stopped for
     */
    event RecoveryStopped(address indexed account);
    /**
     * @notice Emitted when a recovery is executed
     * @param account address - Recovered account
     * @param newOwner bytes  - New owner of the account
     */
    event RecoveryExecuted(address indexed account, bytes newOwner);

    /**
     * @notice Stops the recovery process for the calling account
     * @dev Recovery must be in progress for the account
     */
    function stopRecovery() external virtual {
        if (!isRecovering(msg.sender)) {
            revert Errors.RECOVERY_NOT_STARTED();
        }

        _stopRecovery();
    }

    /**
     * @notice Executes the recovery for the given account
     * @dev Timelock must have expired for the accounts recovery process
     * @param recoveringAddress address - Account to recover
     */
    function executeRecovery(address recoveringAddress) external virtual {
        RecoveryState memory recoveryState = recoveryStates[recoveringAddress];

        if (recoveryState.timelockExpiry == 0) {
            revert Errors.RECOVERY_NOT_STARTED();
        }
        if (recoveryState.timelockExpiry > block.timestamp) {
            revert Errors.RECOVERY_TIMELOCK();
        }

        IClaveAccount(recoveringAddress).resetOwners(recoveryState.newOwner);

        delete recoveryStates[recoveringAddress];

        emit RecoveryExecuted(recoveringAddress, recoveryState.newOwner);
    }

    /**
     * @notice Returns the EIP-712 hash of the recovery data
     * @param recoveryData RecoveryData calldata - Data for the recovery process
     * @return bytes32 - EIP712 hash of the recovery data
     */
    function getEip712Hash(RecoveryData calldata recoveryData) external view returns (bytes32) {
        return _hashTypedDataV4(_recoveryDataHash(recoveryData));
    }

    /**
     * @notice Returns the typehash for the recovery data struct
     * @return bytes32 - Recovery data typehash
     */
    function recoveryDataTypeHash() external pure returns (bytes32) {
        return _RECOVERY_DATA_TYPEHASH;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IModule).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice Returns if the given account is in recovery
     * @param account Account to check for
     * @return Yes if the account is in recovery, No otherwise
     */
    function isRecovering(address account) public view returns (bool) {
        return recoveryStates[account].timelockExpiry != 0;
    }

    /**
     * @notice Returns if the given account is inited
     * @param account Account to check for
     * @return Yes if the account is inited, No otherwise
     */
    function isInited(address account) public view virtual returns (bool);

    function _stopRecovery() internal {
        if (isRecovering(msg.sender)) {
            delete recoveryStates[msg.sender];
            emit RecoveryStopped(msg.sender);
        }
    }

    function _recoveryDataHash(RecoveryData calldata data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _RECOVERY_DATA_TYPEHASH,
                    data.recoveringAddress,
                    keccak256(data.newOwner),
                    data.nonce
                )
            );
    }
}
