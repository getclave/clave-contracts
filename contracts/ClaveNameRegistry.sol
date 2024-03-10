// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ERC721Burnable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {IClaveRegistry} from './interfaces/IClaveRegistry.sol';

contract ClaveNameRegistry is ERC721, ERC721Burnable, AccessControl {
    mapping(bytes => address) public names;
    mapping(uint256 => bytes) public idsToNames;
    mapping(address => bytes) public addressesToNames;

    bytes32 public constant REGISTERER_ROLE = keccak256('REGISTERER_ROLE');

    uint256 private lastTokenId;

    bool public isOnlyClave = true;
    address public claveRegistry;

    event NameRegistered(bytes indexed name, address indexed owner);
    event NameDeleted(bytes indexed name, address indexed owner);
    event ClaveRegistryChanged(address newClaveRegistry);
    event MinterStatusFlipped(bool newStatus);

    constructor(address claveRegistryAddress) ERC721('ClaveNames', 'CLVN') {
        claveRegistry = claveRegistryAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function resolve(bytes memory _name) external view returns (address) {
        return names[_name];
    }

    function resolve(uint256 _tokenId) external view returns (address) {
        return names[idsToNames[_tokenId]];
    }

    function totalSupply() external view returns (uint256) {
        uint256 supply = lastTokenId;

        return supply;
    }

    function register(address to, bytes memory _name) external {
        require(
            to == msg.sender ||
                hasRole(REGISTERER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            '[register] Not authorized to register'
        );
        require(isClave(to), '[register] Not allowed');
        require(names[_name] == address(0), '[register] Name is already registered');
        require(isAlphaNumeric(_name), '[register] Name is not alphanumeric');

        _name = toLower(_name);

        uint256 tokenId = ++lastTokenId;

        names[_name] = to;
        idsToNames[tokenId] = _name;
        addressesToNames[to] = _name;

        _safeMint(to, tokenId);
    }

    function setClaveRegistry(address claveRegistryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claveRegistry = claveRegistryAddress;

        emit ClaveRegistryChanged(claveRegistryAddress);
    }

    function flipMinterStatus() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isOnlyClave = !isOnlyClave;

        emit MinterStatusFlipped(isOnlyClave);
    }

    function burn(uint256 tokenId) public override(ERC721Burnable) {
        address owner = ownerOf(tokenId);

        emit NameDeleted(idsToNames[tokenId], owner);

        delete idsToNames[tokenId];
        delete names[idsToNames[tokenId]];
        delete addressesToNames[owner];

        super.burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function isClave(address account) private view returns (bool) {
        bool isClaveResult = IClaveRegistry(claveRegistry).isClave(account);

        return isOnlyClave ? isClaveResult : true;
    }

    /// @dev Brought by eccdomains
    function toLower(bytes memory name) private pure returns (bytes memory) {
        bytes memory bStr = name;
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return bLower;
    }

    /// @dev Brought by eccdomains
    function isAlphaNumeric(bytes memory name) private pure returns (bool) {
        bytes memory b = name;
        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(char > 0x2F && char < 0x3A) && !(char > 0x60 && char < 0x7B)) return false;
        }
        return true;
    }
}
