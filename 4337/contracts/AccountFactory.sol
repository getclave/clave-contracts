// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Create2} from '@openzeppelin/contracts/utils/Create2.sol';
import {IEntryPoint} from '@account-abstraction/contracts/interfaces/IEntryPoint.sol';

import {Errors} from './libraries/Errors.sol';
import {IClaveRegistry} from './interfaces/IClaveRegistry.sol';
import {ClaveProxy} from './ClaveProxy.sol';

contract AccountFactory is Ownable {
    string public constant VERSION = '1.0.0';

    address private immutable _IMPLEMENTATION;
    address private immutable _REGISTRY;
    IEntryPoint private immutable _ENTRYPOINT;

    // Account authorized to deploy Clave accounts
    address private _deployer;

    /**
     * @notice Event emmited when a new Clave account is created
     * @param accountAddress Address of the newly created Clave account
     */
    event NewClaveAccount(address indexed accountAddress);

    constructor(
        address implementation,
        address registry,
        IEntryPoint entrypoint_,
        address deployer
    ) Ownable() {
        _IMPLEMENTATION = implementation;
        _REGISTRY = registry;
        _ENTRYPOINT = entrypoint_;
        _deployer = deployer;
    }

    function deployAccount(
        bytes32 salt,
        bytes memory initializer
    ) external returns (address accountAddress) {
        // Check the deployer account
        if (msg.sender != _deployer) {
            revert Errors.NOT_FROM_DEPLOYER();
        }

        bytes memory initCode = abi.encodePacked(
            type(ClaveProxy).creationCode,
            uint256(uint160(_IMPLEMENTATION))
        );

        assembly ('memory-safe') {
            accountAddress := create2(0x0, add(initCode, 0x20), mload(initCode), salt)
        }
        if (accountAddress == address(0)) {
            revert Errors.DEPLOYMENT_FAILED();
        }

        // Initialize the account
        bool initializeSuccess;

        assembly ('memory-safe') {
            initializeSuccess := call(
                gas(),
                accountAddress,
                0,
                add(initializer, 0x20),
                mload(initializer),
                0,
                0
            )
        }

        if (!initializeSuccess) {
            revert Errors.INITIALIZATION_FAILED();
        }

        IClaveRegistry(_REGISTRY).register(accountAddress);

        emit NewClaveAccount(accountAddress);
    }

    /**
     * @notice Changes the account authorized to deploy Clave accounts
     * @param newDeployer address - Address of the new account authorized to deploy Clave accounts
     */
    function changeDeployer(address newDeployer) external onlyOwner {
        _deployer = newDeployer;
    }

    function deposit() external payable {
        entrypoint().depositTo{value: msg.value}(address(this));
    }

    function withdrawTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entrypoint().withdrawTo(withdrawAddress, amount);
    }

    function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
        entrypoint().addStake{value: msg.value}(unstakeDelaySec);
    }

    function unlockStake() external onlyOwner {
        entrypoint().unlockStake();
    }

    function withdrawStake(address payable withdrawAddress) external onlyOwner {
        entrypoint().withdrawStake(withdrawAddress);
    }

    function entrypoint() public view returns (IEntryPoint) {
        return _ENTRYPOINT;
    }

    function getAddressForSalt(bytes32 salt) external view returns (address accountAddress) {
        bytes memory initCode = abi.encodePacked(
            type(ClaveProxy).creationCode,
            uint256(uint160(_IMPLEMENTATION))
        );

        accountAddress = Create2.computeAddress(salt, keccak256(initCode));
    }

    /**
     * @notice Returns the address of the implementation contract
     * @return address - Address of the implementation contract
     */
    function getImplementation() external view returns (address) {
        return _IMPLEMENTATION;
    }
}
