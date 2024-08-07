// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ERC721Burnable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {IClaveNameService} from './IClaveNameService.sol';

/**
 * @title ClaveNameService
 * @notice L2 name service contract that is built compatible to resolved as ENS subdomains by L2 resolver
 * @author https://getclave.io
 * @notice Inspired by @stevegachau/optimismresolver
 * @dev Names can only be registered by the owner or authorized accounts
 * @dev Addresses can only have one name at a time
 * @dev Subdomains are stored as ERC-721 assets, cannot be transferred
 * @dev If renewals are enabled, non-renewed names can be burnt after expiration timeline
 */
contract ClaveNameService is IClaveNameService, ERC721, ERC721Burnable, AccessControl {
    // String library for token id conversion
    using Strings for uint256;

    // Subdomains as ERC-721 assets
    struct NameAssets {
        uint256 id; // Token ID as hash of names
        uint256 renewals; // Last renewal timestamp
    }

    // Subdomains as native names
    struct LinkedNames {
        string name; // Subdomain name
    }

    // Current asset supply
    uint256 private totalSupply_;
    // Role to be authorized as default minter
    bytes32 public constant REGISTERER_ROLE = keccak256('REGISTERER_ROLE');
    // Defualt domain expiration timeline
    uint256 public expiration = 365 days;
    // ERC-721 base token URI
    string public baseTokenURI;
    // Allow renewal and expirations
    bool public allowRenewals;

    // Store name to asset data
    mapping(string => NameAssets) public namesToAssets;
    // Store hashed names / token IDs to names
    mapping(uint256 => LinkedNames) public idsToNames;

    // Event to be emitted for name registration
    event NameRegistered(string indexed name, address indexed owner);
    // Event to be emitted for name deletion
    event NameDeleted(string indexed name, address indexed owner);
    // Event to be emitted for name renewal
    event NameRenewed(string indexed name, address indexed owner);
    // Event to be emitted for name expiration
    event NameExpired(string indexed name, address indexed owner);

    /**
     * @notice Constructor function of the contract
     * @param baseURI string    - Base URI for the ERC-721 tokens as subdomains
     * @dev {subdomain}.{domain}.{topdomain} => claver.getclave.eth
     */
    constructor(string memory baseURI) ERC721('ClaveNameService', 'CNS') {
        baseTokenURI = baseURI;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @inheritdoc IClaveNameService
    function resolve(string memory _name) external view returns (address) {
        // Names are stored against keccak hashes of the name converted to 'uint256's
        _name = toLower(_name);
        uint256 hashOfName = uint256(keccak256(abi.encodePacked(_name)));

        return ownerOf(hashOfName);
    }

    /**
     * @notice Total supply of the assets
     * @return - uint256 - Total supply amount
     */
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @notice Register multiple names at once, calles "registerName" as batch
     */
    function registerNameMultiple(
        address[] memory to,
        string[] memory _name
    ) external onlyRegisterer {
        require(to.length == _name.length, '[registerNameMultiple] Invalid input lengths.');

        for (uint256 i = 0; i < to.length; i++) {
            registerName(to[i], _name[i]);
        }
    }

    /**
     * @notice Renew the name to extend the expiration timeline
     * @param _name string - Name to be renewed
     * @dev The names are expired after the renewal date + expiration timeline
     * @dev The names can be renewed by only name owner
     */
    function renewName(string memory _name) external isRenewalsAllowed {
        _name = toLower(_name);
        NameAssets storage asset = namesToAssets[_name];

        require(asset.id != 0, '[renewName] Not registered.');
        require(ownerOf(asset.id) == msg.sender, '[renewName] Not owner.');

        asset.renewals = block.timestamp;

        emit NameRenewed(_name, msg.sender);
    }

    /**
     * @notice Expire and delete the names after the expiration timeline
     * @param _name string - Expired name to be deleted
     * @dev Anyone can expire a name after the expiration timeline
     * @dev Renewals and expirations might be disabled by the admin
     */
    function expireName(string memory _name) external isRenewalsAllowed onlyRegisterer {
        _name = toLower(_name);
        NameAssets memory asset = namesToAssets[_name];

        require(asset.id != 0, '[expireName] Not registered.');
        require(asset.renewals + expiration < block.timestamp, '[expireName] Renewal not over.');

        delete idsToNames[asset.id];
        delete namesToAssets[_name];

        emit NameExpired(_name, ownerOf(asset.id));

        _burn(asset.id);
    }

    /**
     * @notice Change base token URI for the ERC-721 tokens
     * @param baseURI string - New Base URI
     * @return - string - Given base URI
     * @dev Only admin can change the URI
     */
    function setBaseTokenURI(
        string memory baseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (string memory) {
        baseTokenURI = baseURI;
        return baseTokenURI;
    }

    /**
     * @notice Allow or disallow renewals
     * @dev Only admin can change the status
     */
    function flipRenewals() external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowRenewals = !allowRenewals;
    }

    /**
     * @notice Set expiration time for the names
     * @dev Only admin can change the time
     */
    function setExpirationTime(uint256 expirationTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(expirationTime > block.timestamp + 30 days, '[setExpirationTime] Invalid time.');

        expiration = expirationTime;
    }

    /// @inheritdoc IClaveNameService
    function registerName(address to, string memory _name) public onlyRegisterer returns (uint256) {
        _name = toLower(_name);
        require(bytes(_name).length != 0, '[register] Null name');
        require(isAlphanumeric(_name), '[register] Unsupported characters.');
        require(namesToAssets[_name].id == 0, '[register] Already registered.');

        uint256 newTokenId = uint256(keccak256(abi.encodePacked(_name)));
        namesToAssets[_name] = NameAssets(newTokenId, block.timestamp);
        idsToNames[newTokenId].name = _name;

        _safeMint(to, newTokenId);
        emit NameRegistered(_name, to);
        return newTokenId;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) return '';

        return
            bytes(baseTokenURI).length > 0 ? string.concat(baseTokenURI, tokenId.toString()) : '';
    }

    /// @inheritdoc ERC721
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return
            type(IClaveNameService).interfaceId == interfaceId ||
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ERC721Burnable
     * @dev Asset data is cleaned
     */
    function burn(uint256 tokenId) public override(ERC721Burnable) {
        string memory _name = idsToNames[tokenId].name;

        delete idsToNames[tokenId];
        delete namesToAssets[_name];

        emit NameDeleted(_name, msg.sender);

        totalSupply_--;

        super.burn(tokenId);
    }

    /**
     * @inheritdoc ERC721
     * @dev Total supply is applied
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal override {
        totalSupply_++;

        super._safeMint(to, tokenId, _data);
    }

    /**
     * @inheritdoc ERC721
     * @dev Transfers to addresses already have assets are restricted
     */
    function _beforeTokenTransfer(address from, address to, uint256) internal view override {
        require(
            from == address(0) || to == address(0),
            '[_beforeTokenTransfer] Transfers are not allowed..'
        );

        require(
            to == address(0) || balanceOf(to) == 0,
            '[_beforeTokenTransfer] Already have name.'
        );
    }

    // Convert string to lowercase
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

    // Check if string is alphanumeric
    function isAlphanumeric(string memory str) private pure returns (bool) {
        bytes memory b = bytes(str);
        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(char > 0x2F && char < 0x3A) && !(char > 0x60 && char < 0x7B)) return false;
        }
        return true;
    }

    // Modifier to check if caller is authorized for mints and registries
    modifier onlyRegisterer() {
        require(
            hasRole(REGISTERER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            '[]  Not authorized.'
        );
        _;
    }

    // Modifier to check if renewal - expiration timeline is enabled
    modifier isRenewalsAllowed() {
        require(allowRenewals, '[isRenewalsEnabled] Renewals disabled.');
        _;
    }
}
