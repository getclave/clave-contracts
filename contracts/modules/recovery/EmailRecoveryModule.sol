// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IModule} from '../../interfaces/IModule.sol';
import {IEmailRecoveryModule} from '../../interfaces/IEmailRecoveryModule.sol';
import {IClaveAccount} from '../../interfaces/IClave.sol';
import {Errors} from '../../libraries/Errors.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {EmailRecoveryManager, GuardianManager} from '../../EmailRecoveryManager.sol';

contract EmailRecoveryModule is EmailRecoveryManager, IModule, IEmailRecoveryModule {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    CONSTANTS & STORAGE                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Account address to isInited
     */
    mapping(address account => bool) internal inited;

    /**
     * @notice Emitted when a recovery is executed
     * @param account address - Recovered account
     * @param newOwner bytes  - New owner of the account
     */
    event RecoveryExecuted(address indexed account, bytes newOwner);

    constructor(
        address verifier,
        address dkimRegistry,
        address emailAuthImpl,
        address subjectHandler,
        bytes32 _proxyBytecodeHash
    ) EmailRecoveryManager(verifier, dkimRegistry, emailAuthImpl, subjectHandler) {
        proxyBytecodeHash = _proxyBytecodeHash;
    }

    function init(bytes calldata initData) external override {
        if (isInited(msg.sender)) {
            revert Errors.ALREADY_INITED();
        }

        if (!IClaveAccount(msg.sender).isModule(address(this))) {
            revert Errors.MODULE_NOT_ADDED_CORRECTLY();
        }

        (
            address[] memory guardians,
            uint256[] memory weights,
            uint256 threshold,
            uint256 delay,
            uint256 expiry
        ) = abi.decode(initData, (address[], uint256[], uint256, uint256, uint256));

        inited[msg.sender] = true;

        configureRecovery(guardians, weights, threshold, delay, expiry);

        emit Inited(msg.sender);
    }

    function disable() external override {
        inited[msg.sender] = false;

        deInitRecoveryModule();

        emit Disabled(msg.sender);
    }

    function isInited(address account) public view override returns (bool) {
        return inited[account];
    }

    function canStartRecoveryRequest(address account) external view returns (bool) {
        GuardianConfig memory guardianConfig = getGuardianConfig(account);

        return guardianConfig.acceptedWeight >= guardianConfig.threshold;
    }

    function recover(address account, bytes calldata newOwner) internal override {
        IClaveAccount(account).resetOwners(newOwner);

        emit RecoveryExecuted(account, newOwner);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IModule).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
 141 changes: 141 additions & 0 deletions141  
apps/clave-contracts/contracts/modules/recovery/EmailRecoverySubjectHandler.sol
Viewed
Original file line number	Diff line number	Diff line change
@@ -0,0 +1,141 @@
// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IEmailRecoverySubjectHandler} from '../../interfaces/IEmailRecoverySubjectHandler.sol';
import {StringUtils} from '../../libraries/StringUtils.sol';

interface IEmailRecoveryManager {
    function emailRecoveryModule() external view returns (address);
}

/**
 * Handler contract that defines subject templates and how to validate them
 * This is the default subject handler that will work with any validator.
 */
contract EmailRecoverySubjectHandler is IEmailRecoverySubjectHandler {
    error InvalidSubjectParams();
    error InvalidAccount();
    error InvalidRecoveryModule();

    /**
     * @notice Returns a hard-coded two-dimensional array of strings representing the subject
     * templates for an acceptance by a new guardian.
     * @return string[][] A two-dimensional array of strings, where each inner array represents a
     * set of fixed strings and matchers for a subject template.
     */
    function acceptanceSubjectTemplates() public pure returns (string[][] memory) {
        string[][] memory templates = new string[][](1);
        templates[0] = new string[](5);
        templates[0][0] = 'Accept';
        templates[0][1] = 'guardian';
        templates[0][2] = 'request';
        templates[0][3] = 'for';
        templates[0][4] = '{ethAddr}';
        return templates;
    }

    /**
     * @notice Returns a hard-coded two-dimensional array of strings representing the subject
     * templates for email recovery.
     * @return string[][] A two-dimensional array of strings, where each inner array represents a
     * set of fixed strings and matchers for a subject template.
     */
    function recoverySubjectTemplates() public pure returns (string[][] memory) {
        string[][] memory templates = new string[][](1);
        templates[0] = new string[](10);
        templates[0][0] = 'Recover';
        templates[0][1] = 'account';
        templates[0][2] = '{ethAddr}';
        templates[0][3] = 'via';
        templates[0][4] = 'recovery';
        templates[0][5] = 'module';
        templates[0][6] = '{ethAddr}';
        templates[0][7] = 'to';
        templates[0][8] = 'owner';
        templates[0][9] = '{string}';
        return templates;
    }

    /**
     * @notice Extracts the account address to be recovered from the subject parameters of an
     * acceptance email.
     * @param subjectParams The subject parameters of the acceptance email.
     */
    function extractRecoveredAccountFromAcceptanceSubject(
        bytes[] memory subjectParams,
        uint256 /* templateIdx */
    ) public pure returns (address) {
        return abi.decode(subjectParams[0], (address));
    }

    /**
     * @notice Extracts the account address to be recovered from the subject parameters of a
     * recovery email.
     * @param subjectParams The subject parameters of the recovery email.
     */
    function extractRecoveredAccountFromRecoverySubject(
        bytes[] memory subjectParams,
        uint256 /* templateIdx */
    ) public pure returns (address) {
        return abi.decode(subjectParams[0], (address));
    }

    /**
     * @notice Validates the subject params for an acceptance email
     * @param subjectParams The subject parameters of the recovery email.
     * @return accountInEmail The account address in the acceptance email
     */
    function validateAcceptanceSubject(
        uint256 /* templateIdx */,
        bytes[] calldata subjectParams
    ) external pure returns (address) {
        if (subjectParams.length != 1) revert InvalidSubjectParams();

        // The GuardianStatus check in acceptGuardian implicitly
        // validates the account, so no need to re-validate here
        address accountInEmail = abi.decode(subjectParams[0], (address));

        return accountInEmail;
    }

    /**
     * @notice Validates the subject params for an acceptance email
     * @param subjectParams The subject parameters of the recovery email.
     * @param recoveryManager The recovery manager address. Used to help with validation
     * @return accountInEmail The account address in the acceptance email
     * @return calldataHash The keccak256 hash of the recovery calldata. Verified against later when
     * recovery is executed
     */
    function validateRecoverySubject(
        uint256 /* templateIdx */,
        bytes[] calldata subjectParams,
        address recoveryManager
    ) public view returns (address, bytes32) {
        if (subjectParams.length != 3) {
            revert InvalidSubjectParams();
        }

        address accountInEmail = abi.decode(subjectParams[0], (address));
        address recoveryModuleInEmail = abi.decode(subjectParams[1], (address));
        string memory newOwnerHashInEmail = abi.decode(subjectParams[2], (string));
        bytes32 calldataHash = StringUtils.hexToBytes32(newOwnerHashInEmail);

        if (accountInEmail == address(0)) {
            revert InvalidAccount();
        }

        // Even though someone could use a malicious contract as the recoveryManager argument, it
        // does not matter in this case as this is only used as part of the recovery flow in the
        // recovery manager. Passing the recovery manager in the constructor here would result
        // in a circular dependency
        address expectedRecoveryModule = IEmailRecoveryManager(recoveryManager)
            .emailRecoveryModule();
        if (
            recoveryModuleInEmail == address(0) || recoveryModuleInEmail != expectedRecoveryModule
        ) {
            revert InvalidRecoveryModule();
        }

        return (accountInEmail, calldataHash);
    }
}