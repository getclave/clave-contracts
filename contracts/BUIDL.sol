// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title BUIDL Bucks Token - ETHDenver 2024 event token
 * @author https://getclave.io
 */
contract BUIDLBucks is ERC20, ERC20Burnable, Ownable {
    /** <<<<<<<<<<<<<<<< STORAGE ****/

    // "minter" role is used to mint tokens
    mapping(address => bool) private minters;

    /** <<<<<<<<<<<<<<<< EVENTS *****/

    // Event to be emitted when a new minter is added
    event NewMinter(address minter);
    // Event to be emitted when a minter is removed
    event RemovedMinter(address minter);

    /** <<<<<<<<<<<<<<<< FUNCTIONS **/

    // Constructor function of the contract
    constructor() ERC20('BUIDL Bucks', 'BUIDL') Ownable() {}

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
     * @notice This function checks if the given address has "minter" role
     * @param minter address - The address to be checked
     * @return bool - True if the address has "minter" role, false otherwise
     * @dev Owner has "minter" role by default
     */
    function isMinter(address minter) public view returns (bool) {
        return minters[minter] || owner() == minter;
    }

    /** <<<<<<<<<<<<<<<< MODIFIERS **/

    /**
     * @notice This modifier allows only addresses with "minter" role to execute a function, minting tokens
     */
    modifier onlyMinters() {
        require(isMinter(msg.sender), '[] Only minters can mint tokens');
        _;
    }
}
