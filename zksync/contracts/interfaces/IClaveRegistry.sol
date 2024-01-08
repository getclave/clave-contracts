// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IClaveRegistry {
    function register(address account) external;

    function isClave(address account) external view returns (bool);
}
