// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEmailRecoveryModule {
    function canStartRecoveryRequest(address smartAccount) external view returns (bool);
}
