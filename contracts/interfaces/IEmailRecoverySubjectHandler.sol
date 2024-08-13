// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEmailRecoverySubjectHandler {
    function acceptanceSubjectTemplates() external pure returns (string[][] memory);

    function recoverySubjectTemplates() external pure returns (string[][] memory);

    function extractRecoveredAccountFromAcceptanceSubject(
        bytes[] memory subjectParams,
        uint256 templateIdx
    ) external view returns (address);

    function extractRecoveredAccountFromRecoverySubject(
        bytes[] memory subjectParams,
        uint256 templateIdx
    ) external view returns (address);

    function validateAcceptanceSubject(
        uint256 templateIdx,
        bytes[] memory subjectParams
    ) external view returns (address);

    function validateRecoverySubject(
        uint256 templateIdx,
        bytes[] memory subjectParams,
        address recoveryManager
    ) external view returns (address, bytes32);
}
