// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ERC721Burnable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';

/**
 * @title ClaveNames
 * @author https://getclave.io
 * @notice https://github.com/stevegachau/optimismresolver
 */
contract ClaveNames is ERC721, ERC721Burnable, AccessControl {
    struct NameAssets {
        uint256 id;
    }
    struct LinkedNames {
        string name;
    }

    bytes32 public constant REGISTERER_ROLE = keccak256('REGISTERER_ROLE');
    uint256 private lastTokenId;
    string private baseTokenURI;

    mapping(string => NameAssets) public namesToAddresses;
    mapping(uint256 => LinkedNames) public idsToNames;

    event NameRegistered(string indexed name, address indexed owner);
    event NameDeleted(string indexed name, address indexed owner);

    constructor(string memory baseURI) ERC721('ClaveNames', 'CLVN') {
        baseTokenURI = baseURI;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function register(address to, string memory _name) external returns (uint256) {
        string memory domain = toLower(_name);
        uint256 newItemId = ++lastTokenId;

        require(
            to == msg.sender ||
                hasRole(REGISTERER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            '[register] Not authorized.'
        );
        require(namesToAddresses[domain].id == 0, '[register] Already registered.');
        require(bytes(domain).length != 0, '[register] Null name');
        require(isAlphanumeric(domain), '[register] Unsupported characters.');

        namesToAddresses[domain].id = newItemId;
        idsToNames[newItemId].name = domain;

        _mint(to, newItemId);

        emit NameRegistered(domain, to);

        return newItemId;
    }

    function resolve(string memory _name) external view returns (address) {
        string memory domain = toLower(_name);
        if (namesToAddresses[domain].id == 0) {
            return address(0);
        }
        address owner = ownerOf(namesToAddresses[domain].id);
        return owner;
    }

    function totalSupply() external view returns (uint256) {
        uint256 supply = lastTokenId;

        return supply;
    }

    function setBaseTokenURI(
        string memory baseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (string memory) {
        baseTokenURI = baseURI;
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory domain = idsToNames[tokenId].name;
        string memory tokenlink = string(abi.encodePacked(baseTokenURI, domain));
        return tokenlink;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public override(ERC721Burnable) {
        string memory domain = idsToNames[tokenId].name;

        delete idsToNames[tokenId];
        delete namesToAddresses[domain];

        emit NameDeleted(domain, msg.sender);

        super.burn(tokenId);
    }

    function toLower(string memory str) private pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function isAlphanumeric(string memory str) private pure returns (bool) {
        bytes memory b = bytes(str);
        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(char > 0x2F && char < 0x3A) && !(char > 0x60 && char < 0x7B)) return false;
        }
        return true;
    }
}
