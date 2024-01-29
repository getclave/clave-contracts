// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';

/**
 * @title BUIDL Token - ETHDenver 2024 event token
 * @author https://getclave.io
 */
contract BUIDLToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    /** <<<<<<<<<<<<<<<< STORAGE ****/

    // "minter" role is used to mint tokens
    mapping(address => bool) private minters;
    // "master" role is used to change the token receivers
    mapping(address => bool) private masters;
    // "receiver" role is used to receive tokens
    mapping(address => bool) private receivers;

    /** <<<<<<<<<<<<<<<< EVENTS *****/

    // Event to be emitted when a new minter is added
    event NewMinter(address minter);
    // Event to be emitted when a minter is removed
    event RemovedMinter(address minter);
    // Event to be emitted when a new master is added
    event NewMaster(address master);
    // Event to be emitted when a master is removed
    event RemovedMaster(address master);
    // Event to be emitted when a new receiver is added
    event NewReceiver(address receiver);
    // Event to be emitted when a receiver is removed
    event RemovedReceiver(address receiver);

    /** <<<<<<<<<<<<<<<< FUNCTIONS **/

    // Constructor function of the contract
    constructor() ERC20('BUIDL Token', 'BUIDL') Ownable() ERC20Permit('BUIDL Token') {}

    /**
     * @notice This function allows creating new tokens
     * @param to address     - The receiver address where new minted tokens are sent
     * @param amount uint256 - The amount of tokens to mint
     * @dev Only addresses with "minter" role can mint tokens
     */
    function mint(address to, uint256 amount) external onlyMinters {
        _mint(to, amount);
    }

    /**
     * @notice This function allows attach "minter" role to new addresses
     * @param newMinters address[] - The addresses to be added as minters
     * @dev Only owner can add new minters
     * @dev Addresses with existing roles will cause errors
     */
    function allowMinters(address[] calldata newMinters) external onlyOwner {
        for (uint i = 0; i < newMinters.length; i++) {
            address newMinter = newMinters[i];
            require(!isMinter(newMinter), '[allowMinters] Address is already a minter');

            minters[newMinter] = true;
            emit NewMinter(newMinter);
        }
    }

    /**
     * @notice This function allows removing "minter" role from the addresses
     * @param removedMinters address[] - The addresses to be removed from minters
     * @dev Only owner can add remove minters
     * @dev Addresses without roles will cause errors
     */
    function disallowMinters(address[] calldata removedMinters) external onlyOwner {
        for (uint i = 0; i < removedMinters.length; i++) {
            address removedMinter = removedMinters[i];
            require(isMinter(removedMinter), '[disallowMinters] Address is already not a minter');

            minters[removedMinter] = false;
            emit RemovedMinter(removedMinter);
        }
    }

    /**
     * @notice This function allows attach "master" role to new addresses
     * @param newMasters address[] - The addresses to be added as masters
     * @dev Only owner can add new masters
     * @dev Addresses with existing roles will cause errors
     */
    function allowMasters(address[] calldata newMasters) external onlyOwner {
        for (uint i = 0; i < newMasters.length; i++) {
            address newMaster = newMasters[i];
            require(!isMaster(newMaster), '[allowMasters] Address is already a master');

            masters[newMaster] = true;
            emit NewMaster(newMaster);
        }
    }

    /**
     * @notice This function allows removing "master" role from the addresses
     * @param removedMasters address[] - The addresses to be removed from masters
     * @dev Only owner can add remove masters
     * @dev Addresses without roles will cause errors
     */
    function disallowMasters(address[] calldata removedMasters) external onlyOwner {
        for (uint i = 0; i < removedMasters.length; i++) {
            address removedMaster = removedMasters[i];
            require(isMaster(removedMaster), '[disallowMasters] Address is already not a master');

            masters[removedMaster] = false;
            emit RemovedMaster(removedMaster);
        }
    }

    /**
     * @notice This function allows attach "receiver" role to new addresses
     * @param newReceivers address[] - The addresses to be added as receivers
     * @dev Only masters can add new receivers
     * @dev Addresses with existing roles will cause errors
     */
    function allowReceivers(address[] calldata newReceivers) external onlyMasters {
        for (uint i = 0; i < newReceivers.length; i++) {
            address newReceiver = newReceivers[i];
            require(!isReceiver(newReceiver), '[allowReceivers] Address is already a receiver');

            receivers[newReceiver] = true;
            emit NewReceiver(newReceiver);
        }
    }

    /**
     * @notice This function allows removing "receiver" role from the addresses
     * @param removedReceivers address[] - The addresses to be removed from receivers
     * @dev Only masters can add remove receivers
     * @dev Addresses without roles will cause errors
     */
    function disallowReceivers(address[] calldata removedReceivers) external onlyMasters {
        for (uint i = 0; i < removedReceivers.length; i++) {
            address removedReceiver = removedReceivers[i];
            require(isReceiver(removedReceiver), '[disallowReceivers] Address is not a receiver');

            receivers[removedReceivers[i]] = false;
            emit RemovedReceiver(removedReceiver);
        }
    }

    /**
     * @notice This function checks if the given address has "minter" role
     * @param minter address - The address to be checked
     * @return bool - True if the address has "minter" role, false otherwise
     * @dev Owner has "minter" role by default
     */
    function isMinter(address minter) public view returns (bool) {
        return minters[minter] || owner() == minter;
    }

    /**
     * @notice This function checks if the given address has "master" role
     * @param master address - The address to be checked
     * @return bool - True if the address has "master" role, false otherwise
     * @dev Owner has "master" role by default
     */
    function isMaster(address master) public view returns (bool) {
        return masters[master] || owner() == master;
    }

    /**
     * @notice This function checks if the given address has "receiver" role
     * @param receiver address - The address to be checked
     * @return bool - True if the address has "receiver" role, false otherwise
     */
    function isReceiver(address receiver) public view returns (bool) {
        return receivers[receiver];
    }

    /**
     * @notice `transfer` function is overriden to allow only addresses with "receiver" roles to receive tokens
     * @inheritdoc ERC20
     */
    function transfer(address to, uint256 amount) public override checkReceiver(to) returns (bool) {
        return super.transfer(to, amount);
    }

    /**
     * @notice `transferFrom` function is overriden to allow only addresses with "receiver" roles to receive tokens
     * @inheritdoc ERC20
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override checkReceiver(to) returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    /** <<<<<<<<<<<<<<<< MODIFIERS **/

    /**
     * @notice This modifier allows only addresses with "minter" role to execute a function, minting tokens
     */
    modifier onlyMinters() {
        require(isMinter(msg.sender), '[] Only minters can mint tokens');
        _;
    }

    /**
     * @notice This modifier allows only addresses with "master" role to to execute a function, chaing token receiver
     */
    modifier onlyMasters() {
        require(isMaster(msg.sender), '[] Only masters can change the token receivers');
        _;
    }

    /**
     * @notice This modifier allows only addresses with "receiver" role to receive token, be used in transfer and transferFrom functions
     * @param to address - The address to be checked
     */
    modifier checkReceiver(address to) {
        require(isReceiver(to), '[] Only receivers can receive tokens');
        _;
    }
}
