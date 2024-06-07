// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IResolver} from "../interfaces/IResolver.sol";
import {StorageProof, StorageProofVerifier} from "./StorageProofVerifier.sol";

interface IResolverService {
    function resolve(bytes calldata name, bytes calldata data) external view returns(StorageProof memory proof);
}

/// @notice L1 Resolver contract that'll be used for L2 Registry contract
/// @dev This is for demo purposes, Registry is not safe to use
contract ClaveNameResolver is IResolver, Ownable {
    /// @notice Thrown when an offchain lookup will be performed
    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    /// @notice Storage slot for the mapping index, specific to Registry contract
    uint256 constant public NAMES_MAPPING_SLOT = 2;

    /// @notice Storage proof verifier contract
    StorageProofVerifier public storageProofVerifier;

    /// @notice URL of the offchain resolver
    string public url;

    /// @notice Address of the registry contract on L2
    address public registry;

    constructor(string memory _url, address _registry, StorageProofVerifier _storageProofVerifier) {
        url = _url;
        registry = _registry;
        storageProofVerifier = _storageProofVerifier;
    }

    function setUrl(string memory _url) external onlyOwner {
        url = _url;
    }

    function setRegistry(address _registry) external onlyOwner {
        registry = _registry;
    }

    function setStorageProofVerifier(StorageProofVerifier _storageProofVerifier) external onlyOwner {
        storageProofVerifier = _storageProofVerifier;
    }

    /// @dev https://ethereum.stackexchange.com/questions/133473/how-to-calculate-the-location-index-slot-in-storage-of-a-mapping-key
    function getStorageLocationForKey(bytes memory _key) public pure returns(bytes32) {
        return keccak256(abi.encode(_key, NAMES_MAPPING_SLOT));
    }

    function extractSubdomain(bytes memory _name) returns (string _domain) {
        _domain = string(_name);
    }


    /// @notice Resolves a name to a value
    /// @param _name The name to resolve
    function resolve(bytes memory _name, bytes memory _data) external view override returns (bytes memory) {
        bytes memory callData = abi.encodeWithSelector(IResolverService.resolve.selector, _name, _data);

        // Fill URLs
        string[] memory urls = new string[](1);
        urls[0] = url;

        bytes32 registryStorageKey = getStorageLocationForKey(_name);

        revert OffchainLookup(
            address(this),
            urls,
            callData,
            RegistryResolver.resolveWithProof.selector,
            abi.encode(registry, registryStorageKey)
        );
    }

    /// @notice Callback used by CCIP read compatible clients to verify and parse the response.
    /// @param _response ABI encoded StorageProof struct
    /// @param _extraData ABI encoded (account, key) tuple
    /// @return ABI encoded value of the storage key
    function resolveWithProof(bytes memory _response, bytes memory _extraData) external view returns (bytes memory) {
        (StorageProof memory proof) = abi.decode(_response, (StorageProof));
        (address account, uint256 key) = abi.decode(_extraData, (address, uint256));

        // Override account and key of the proof to make sure it is correct address and key
        proof.account = account;
        proof.key = key;

        require(storageProofVerifier.verify(proof), "StorageProofVerifier: Invalid storage proof");

        // If there's an address for the name, this should be an address
        // But example code is returning bytes and we're doing the same
        return abi.encodePacked(proof.value);
    }

}