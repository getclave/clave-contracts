// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;


import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title SmoothieStore
 * @author https://getclave.io
 */
contract SmoothieStore is Ownable {
    /**
     * @notice Mapping to store the smoothie balance of each address
     */
    mapping(address => uint256) public smoothieBalance;

    /**
     * @notice Variable to store the limit of smoothies an address can buy
     */
    uint256 public smoothieLimit;

    /**
     * @notice Constructor to initialize the smoothie limit when the contract is deployed
     * @param _smoothieLimit uint256 - The initial limit of smoothies that an address can buy
     */
    constructor(uint256 _smoothieLimit) {
        smoothieLimit = _smoothieLimit;
    }

    /**
     * @notice Function to buy a smoothie
     * @dev The function increments the caller's smoothie balance by 1 if the limit is not exceeded
     * @dev The caller's smoothie balance must be less than or equal to the smoothie limit
     */
    function buySmoothie() external {
        require(smoothieBalance[msg.sender] <= smoothieLimit, "SmoothieStore: limit exceeded");

        smoothieBalance[msg.sender] += 1;
    }

    /**
     * @notice Function to set a new smoothie limit
     * @param _smoothieLimit uint256 - The new limit of smoothies that an address can buy
     */
    function setSmoothieLimit(uint256 _smoothieLimit) external onlyOwner{
        smoothieLimit = _smoothieLimit;
    }
}