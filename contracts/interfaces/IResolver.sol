// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IResolver {
    function resolve(bytes memory name, bytes memory data) external view returns (bytes memory);
}
