// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {DEPLOYER_SYSTEM_CONTRACT, IContractDeployer} from '@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol';
import {SystemContractsCaller} from '@matterlabs/zksync-contracts/l2/system-contracts/libraries/SystemContractsCaller.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {Errors} from './libraries/Errors.sol';
import {IClaveRegistry} from './interfaces/IClaveRegistry.sol';

/**
 * @title Factory contract to create Clave accounts in zkSync Era
 * @author https://getclave.io
 */
contract AccountFactory is Ownable {
    // Factory versioning
    string public constant VERSION = '1.0.0';

    // Addresses of the implementation and registry contract
    address private immutable _IMPLEMENTATION;
    address private immutable _REGISTRY;

    // Account creation bytecode hash
    bytes32 public proxyBytecodeHash;
    // Account authorized to deploy Clave accounts
    address private _deployer;

    /**
     * @notice Event emmited when a new Clave account is created
     * @param accountAddress Address of the newly created Clave account
     */
    event NewClaveAccount(address indexed accountAddress);

    /**
     * @notice Constructor function of the factory contract
     * @param implementation address     - Address of the implementation contract
     * @param registry address           - Address of the registry contract
     * @param _proxyBytecodeHash address - Hash of the bytecode of the clave proxy contract
     * @param deployer address           - Address of the account authorized to deploy Clave accounts
     */
    constructor(
        address implementation,
        address registry,
        bytes32 _proxyBytecodeHash,
        address deployer
    ) Ownable() {
        _IMPLEMENTATION = implementation;
        _REGISTRY = registry;
        proxyBytecodeHash = _proxyBytecodeHash;
        _deployer = deployer;
    }

    /**
     * @notice Deploys a new Clave account
     * @dev Account address depends only on salt
     * @param salt bytes32             - Salt to be used for the account creation
     * @param initializer bytes memory - Initializer data for the account
     * @return accountAddress address - Address of the newly created Clave account
     */
    function deployAccount(
        bytes32 salt,
        bytes memory initializer
    ) external returns (address accountAddress) {
        // Check the deployer account
        if (msg.sender != _deployer) {
            revert Errors.NOT_FROM_DEPLOYER();
        }

        // Deploy the implementation contract
        (bool success, bytes memory returnData) = SystemContractsCaller.systemCallWithReturndata(
            uint32(gasleft()),
            address(DEPLOYER_SYSTEM_CONTRACT),
            uint128(0),
            abi.encodeCall(
                DEPLOYER_SYSTEM_CONTRACT.create2Account,
                (
                    salt,
                    proxyBytecodeHash,
                    abi.encode(_IMPLEMENTATION),
                    IContractDeployer.AccountAbstractionVersion.Version1
                )
            )
        );

        if (!success) {
            revert Errors.DEPLOYMENT_FAILED();
        }

        // Decode the account address
        (accountAddress) = abi.decode(returnData, (address));

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

    /**
     * @notice Returns the address of the Clave account that would be created with the given salt
     * @param salt bytes32 - Salt to be used for the account creation
     * @return accountAddress address - Address of the Clave account that would be created with the given salt
     */
    function getAddressForSalt(bytes32 salt) external view returns (address accountAddress) {
        accountAddress = IContractDeployer(DEPLOYER_SYSTEM_CONTRACT).getNewAddressCreate2(
            address(this),
            proxyBytecodeHash,
            salt,
            abi.encode(_IMPLEMENTATION)
        );
    }

    /**
     * @notice Returns the address of the implementation contract
     * @return address - Address of the implementation contract
     */
    function getImplementation() external view returns (address) {
        return _IMPLEMENTATION;
    }
}
