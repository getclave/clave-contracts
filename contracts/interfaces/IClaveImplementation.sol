// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/**
 * @title Interface of the main account contract for the Clave wallet infrastructure in zkSync Era
 * @author https://getclave.io
 */
interface IClaveImplementation {
    /**
     * @notice ERC165
     * @param interfaceId bytes4 - the interface id to check
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
