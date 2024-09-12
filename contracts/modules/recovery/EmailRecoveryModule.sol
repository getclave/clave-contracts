// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IModule} from "../../interfaces/IModule.sol";
import {IEmailRecoveryModule} from "@zk-email/email-recovery/src/interfaces/IEmailRecoveryModule.sol";
import {IClaveAccount} from "../../interfaces/IClave.sol";
import {Errors} from "../../libraries/Errors.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {EmailRecoveryManagerZkSync} from "@zk-email/email-recovery/src/EmailRecoveryManagerZkSync.sol";
import {GuardianManager} from "@zk-email/email-recovery/src/GuardianManager.sol";

contract EmailRecoveryModule is
    EmailRecoveryManagerZkSync,
    IModule,
    IEmailRecoveryModule
{
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
        address commandHandler,
        bytes32 _proxyBytecodeHash
    )
        EmailRecoveryManager(
            verifier,
            dkimRegistry,
            emailAuthImpl,
            commandHandler
        )
    {
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
        ) = abi.decode(
                initData,
                (address[], uint256[], uint256, uint256, uint256)
            );

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

    function canStartRecoveryRequest(
        address account
    ) external view returns (bool) {
        GuardianConfig memory guardianConfig = getGuardianConfig(account);

        return guardianConfig.acceptedWeight >= guardianConfig.threshold;
    }

    function recover(
        address account,
        bytes calldata newOwner
    ) internal override {
        IClaveAccount(account).resetOwners(newOwner);

        emit RecoveryExecuted(account, newOwner);
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) external pure override returns (bool) {
        return
            interfaceId == type(IModule).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
