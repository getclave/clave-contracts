// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IEmailRecoveryCommandHandler} from "@zk-email/email-recovery/src/interfaces/IEmailRecoveryCommandHandler.sol";
import {IEmailRecoveryManager} from "@zk-email/email-recovery/src/interfaces/IEmailRecoveryManager.sol";
import {StringUtils} from "@zk-email/email-recovery/src/libraries/StringUtils.sol";

/**
 * Handler contract that defines command templates and how to validate them
 * This is the default command handler that will work with any validator.
 */
contract EmailRecoveryCommandHandler is IEmailRecoveryCommandHandler {
    error InvalidCommandParams();
    error InvalidAccount();
    error InvalidRecoveryModule();

    /**
     * @notice Returns a hard-coded two-dimensional array of strings representing the command
     * templates for an acceptance by a new guardian.
     * @return string[][] A two-dimensional array of strings, where each inner array represents a
     * set of fixed strings and matchers for a command template.
     */
    function acceptanceCommandTemplates()
        public
        pure
        returns (string[][] memory)
    {
        string[][] memory templates = new string[][](1);
        templates[0] = new string[](5);
        templates[0][0] = "Accept";
        templates[0][1] = "guardian";
        templates[0][2] = "request";
        templates[0][3] = "for";
        templates[0][4] = "{ethAddr}";
        return templates;
    }

    /**
     * @notice Returns a hard-coded two-dimensional array of strings representing the command
     * templates for email recovery.
     * @return string[][] A two-dimensional array of strings, where each inner array represents a
     * set of fixed strings and matchers for a command template.
     */
    function recoveryCommandTemplates()
        public
        pure
        returns (string[][] memory)
    {
        string[][] memory templates = new string[][](1);
        templates[0] = new string[](10);
        templates[0][0] = "Recover";
        templates[0][1] = "account";
        templates[0][2] = "{ethAddr}";
        templates[0][3] = "via";
        templates[0][4] = "recovery";
        templates[0][5] = "module";
        templates[0][6] = "{ethAddr}";
        templates[0][7] = "to";
        templates[0][8] = "owner";
        templates[0][9] = "{string}";
        return templates;
    }

    /**
     * @notice Extracts the account address to be recovered from the command parameters of an
     * acceptance email.
     * @param commandParams The command parameters of the acceptance email.
     */
    function extractRecoveredAccountFromAcceptanceCommand(
        bytes[] memory commandParams,
        uint256 /* templateIdx */
    ) public pure returns (address) {
        return abi.decode(commandParams[0], (address));
    }

    /**
     * @notice Extracts the account address to be recovered from the command parameters of a
     * recovery email.
     * @param commandParams The command parameters of the recovery email.
     */
    function extractRecoveredAccountFromRecoveryCommand(
        bytes[] memory commandParams,
        uint256 /* templateIdx */
    ) public pure returns (address) {
        return abi.decode(commandParams[0], (address));
    }

    /**
     * @notice Validates the command params for an acceptance email
     * @param templateIdx The index of the template used for the acceptance email
     * @param commandParams The command parameters of the recovery email.
     * @return accountInEmail The account address in the acceptance email
     */
    function validateAcceptanceCommand(
        uint256 templateIdx,
        bytes[] calldata commandParams
    ) external pure returns (address) {
        if (templateIdx != 0 || commandParams.length != 1)
            revert InvalidCommandParams();

        // The GuardianStatus check in acceptGuardian implicitly
        // validates the account, so no need to re-validate here
        address accountInEmail = abi.decode(commandParams[0], (address));

        return accountInEmail;
    }

    /**
     * @notice Validates the command params for an acceptance email
     * @param templateIdx The index of the template used for the recovery email
     * @param commandParams The command parameters of the recovery email.
     * @return accountInEmail The account address in the acceptance email
     */
    function validateRecoveryCommand(
        uint256 templateIdx,
        bytes[] calldata commandParams
    ) public view returns (address) {
        if (templateIdx != 0 || commandParams.length != 3) {
            revert InvalidCommandParams();
        }

        address accountInEmail = abi.decode(commandParams[0], (address));
        address recoveryModuleInEmail = abi.decode(commandParams[1], (address));

        if (accountInEmail == address(0)) {
            revert InvalidAccount();
        }

        address expectedRecoveryModule = address(this);
        if (recoveryModuleInEmail != expectedRecoveryModule) {
            revert InvalidRecoveryModule();
        }

        return accountInEmail;
    }

    /**
     * @notice parses the recovery data hash from the command params. The data hash is
     * verified against later when recovery is executed
     * @dev recoveryDataHash = abi.encode(validator, recoveryFunctionCalldata)
     * @param templateIdx The index of the template used for the recovery request
     * @param commandParams The command parameters of the recovery email
     * @return recoveryDataHash The keccak256 hash of the recovery data
     */
    function parseRecoveryDataHash(
        uint256 templateIdx,
        bytes[] memory commandParams
    ) external view returns (bytes32) {
        if (templateIdx != 0 || commandParams.length != 3) {
            revert InvalidCommandParams();
        }
        address accountInEmail = abi.decode(commandParams[0], (address));
        address moduleInEmail = abi.decode(commandParams[1], (address));
        address newOwnerInEmail = abi.decode(commandParams[2], (address));
        bytes memory recoveryCalldata = abi.encode(
            moduleInEmail,
            newOwnerInEmail
        );
        return keccak256(abi.encode(accountInEmail, recoveryCalldata));
    }
}
