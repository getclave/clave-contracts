// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ERC721Burnable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';

/**
 * @title ClaveNameService
 * @notice L2 name service contract that built compatible to resolved as ENS subdomains by L2 resolver
 * @author https://getclave.io
 * @notice Inspired by @stevegachau/optimismresolver
 * @dev Names can only be registered by the owner or authorized accounts
 * @dev Addresses can only have one name at a time
 * @dev Subdomains are stored as ERC-721 assets, can only be transferred to another address without any assets
 * @dev If renewals are enabled, non-renewed names can be burnt after expiration timeline
 * TODO: May limit for Clave accounts
 */
contract ClaveNameService is ERC721, ERC721Burnable, AccessControl {
    // Subdomains as ERC-721 assets
    struct NameAssets {
        uint256 id; // Token ID as ENS namehash
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
    // ENS domain namehash to be used for subdomains
    bytes32 public domainNamehash;
    // ERC-721 base token URI
    string public baseTokenURI;
    // Allow renewal and expirations
    bool public allowRenewals;

    // Store name to asset data
    mapping(string => NameAssets) public namesToAssets;
    // Store subdomain namehashes / token IDs to names
    mapping(uint256 => LinkedNames) public idsToNames;

    // Event to be emitted for name registration
    event NameRegistered(string indexed name, address indexed owner);
    // Event to be emitted for name deletion
    event NameDeleted(string indexed name, address indexed owner);
    // Event to be emitted for name transfer
    event NameTransferred(string indexed name, address indexed from, address indexed to);
    // Event to be emitted for name renewal
    event NameRenewed(string indexed name, address indexed owner);
    // Event to be emitted for name expiration
    event NameExpired(string indexed name, address indexed owner);

    /**
     * @notice Constructor function of the contract
     *
     * @param domain string    - ENS domain to build subdomains
     * @param topdomain string - ENS topdomain of the domain
     * @param baseURI string   - Base URI for the ERC-721 tokens as subdomains
     *
     * @dev {subdomain}.{domain}.{topdomain} => claver.getclave.eth
     */
    constructor(
        string memory domain,
        string memory topdomain,
        string memory baseURI
    ) ERC721('ClaveNameService', 'CNS') {
        domain = toLower(domain);
        topdomain = toLower(topdomain);
        domainNamehash = namehash(domain, topdomain);

        baseTokenURI = baseURI;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Resolve name to address from L2
     * @param _name string - Subdomain name to resolve
     * @return - address - Owner of the name
     */
    function resolve(string memory _name) external view returns (address) {
        // Domain NFTs are stored against the namehashes of the subdomains
        _name = toLower(_name);
        bytes32 subdomainNamehash = namehash(_name);

        return ownerOf(uint256(subdomainNamehash));
    }

    /**
     * @notice Total supply of the assets
     * @return - uint256 - Total supply amount
     */
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @notice Register a new name and issue as a ENS subdomain
     * @param to address   - Owner of the registered address
     * @param _name string - Name to be registered
     * @dev Only owner of the given address or authorized accounts can register a name
     */
    function register(
        address to,
        string memory _name
    ) external onlyRoleOrOwner(to) returns (uint256) {
        string memory subdomain = toLower(_name);
        require(bytes(subdomain).length != 0, '[register] Null name');
        require(isAlphanumeric(subdomain), '[register] Unsupported characters.');
        require(namesToAssets[subdomain].id == 0, '[register] Already registered.');

        uint256 newTokenId = uint256(namehash(subdomain));
        namesToAssets[subdomain] = NameAssets(newTokenId, block.timestamp);
        idsToNames[newTokenId].name = subdomain;

        _safeMint(to, newTokenId);
        emit NameRegistered(subdomain, to);
        return newTokenId;
    }

    /**
     * @notice Renew the name to extend the expiration timeline
     * @param _name string - Name to be renewed
     * @dev The names are expired after the renewal date + expiration timeline
     * @dev The names can be renewed by only name owner
     */
    function renewName(string memory _name) external isRenewalsAllowed {
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
    function expireName(string memory _name) external isRenewalsAllowed {
        string memory domain = toLower(_name);
        NameAssets memory asset = namesToAssets[domain];

        require(asset.id != 0, '[expireName] Not registered.');
        require(asset.renewals + expiration < block.timestamp, '[expireName] Renewal not over.');

        delete idsToNames[asset.id];
        delete namesToAssets[domain];

        emit NameExpired(domain, ownerOf(asset.id));

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
        expiration = expirationTime;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory tokenlink = string(abi.encodePacked(baseTokenURI, tokenId));

        return tokenlink;
    }

    /// @inheritdoc ERC721
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ERC721Burnable
     * @dev Asset data is cleaned
     */
    function burn(uint256 tokenId) public override(ERC721Burnable) {
        string memory domain = idsToNames[tokenId].name;

        delete idsToNames[tokenId];
        delete namesToAssets[domain];

        emit NameDeleted(domain, msg.sender);

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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(balanceOf(to) == 0, '[] Already have name.');

        string memory domain = idsToNames[tokenId].name;
        emit NameTransferred(domain, from, to);
    }

    /**
     * @param subdomain string - Subdomain name
     * @return subdomainNamehash bytes32 - ENS namehash of the subdomain by contract domain namehash
     * @dev See ENS namehashes https://docs.ens.domains/resolution/names#namehash
     * @dev {subdomain}.{domain}.{topdomain} => claver.getclave.eth
     */
    function namehash(string memory subdomain) private view returns (bytes32 subdomainNamehash) {
        subdomainNamehash = keccak256(
            abi.encodePacked(domainNamehash, keccak256(abi.encodePacked(subdomain)))
        );

        return subdomainNamehash;
    }

    /**
     * @param domain string - domain name
     * @param topdomain string - topdomain name
     * @return domainNamehash_ bytes32 - ENS namehash of the domain
     * @dev See ENS namehashes https://docs.ens.domains/resolution/names#namehash
     * @dev {domain}.{topdomain} => getclave.eth
     */
    function namehash(
        string memory domain,
        string memory topdomain
    ) private pure returns (bytes32 domainNamehash_) {
        bytes32 topdomainNamehash = keccak256(
            abi.encodePacked(bytes32(0x00), keccak256(abi.encodePacked(topdomain)))
        );

        domainNamehash_ = keccak256(
            abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(domain)))
        );

        return domainNamehash_;
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

    // Modifier to check if caller is the asset owner address or authorized
    modifier onlyRoleOrOwner(address to) {
        require(
            to == msg.sender ||
                hasRole(REGISTERER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            '[] Not authorized.'
        );

        _;
    }

    // Modifier to check if renewal - expiration timeline is enabled
    modifier isRenewalsAllowed() {
        require(allowRenewals, '[isRenewalsEnabled] Renewals disabled.');
        _;
    }
}
