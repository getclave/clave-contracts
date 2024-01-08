// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IClave {
    function resetOwners(bytes calldata pubKey) external;

    function isModule(address addr) external view returns (bool);

    function isHook(address addr) external view returns (bool);
}
