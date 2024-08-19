// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IClaveNameService {
    /**
     * @notice Resolve name to address from L2
     * @param _name string - Subdomain name to resolve
     * @return - address - Owner of the name
     */
    function resolve(string memory _name) external view returns (address);

    /**
     * @notice Register a new name and issue as a ENS subdomain
     * @param to address   - Owner of the registered address
     * @param _name string - Name to be registered
     * @dev Only owner of the given address or authorized accounts can register a name
     */
    function registerName(address to, string memory _name) external returns (uint256);
}
