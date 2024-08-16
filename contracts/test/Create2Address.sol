pragma solidity ^0.8.17;

import {L2ContractHelper} from '@matterlabs/zksync-contracts/l2/contracts/L2ContractHelper.sol';
import {DEPLOYER_SYSTEM_CONTRACT, IContractDeployer} from '@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol';
import {SystemContractsCaller} from '@matterlabs/zksync-contracts/l2/system-contracts/libraries/SystemContractsCaller.sol';

import {EmailAuth, ERC1967Proxy, Create2} from '../EmailRecoveryManager.sol';

import "hardhat/console.sol";

contract Create2Address {

    EmailAuth emailAuth;
    bytes32 proxyBytecodeHash;

    constructor() {
        console.log("constructor");
        emailAuth = new EmailAuth();
        proxyBytecodeHash = bytes32(0x0100002f564d6017603b63f3adc01ad4c4367e355ef47d34a07a06ea98359c18);
    }

    function emailAuthImplementation() public view returns (address) {
        console.log("emailAuthImplementation");
        return address(emailAuth);
    }

    function chainId() public view returns (uint256) {
        return block.chainid;
    }

    /// @notice Computes the address for email auth contract using the CREATE2 opcode.
    /// @dev This function utilizes the `Create2` library to compute the address. The computation uses a provided account address to be recovered, account salt,
    /// and the hash of the encoded ERC1967Proxy creation code concatenated with the encoded email auth contract implementation
    /// address and the initialization call data. This ensures that the computed address is deterministic and unique per account salt.
    /// @param recoveredAccount The address of the account to be recovered.
    /// @param accountSalt A bytes32 salt value, which is assumed to be unique to a pair of the guardian's email address and the wallet address to be recovered.
    /// @return address The computed address.
    function computeEmailAuthAddress(
        address recoveredAccount,
        bytes32 accountSalt
    ) public view returns (address) {
        // If on zksync, we use L2ContractHelper.computeCreate2Address
        // if (block.chainid == 324 || block.chainid == 300) {
            // TODO: The bytecodeHash is hardcoded here because type(ERC1967Proxy).creationCode doesn't work on eraVM currently
            // If you failed some test cases, check the bytecodeHash by yourself
            // see, test/ComputeCreate2Address.t.sol
            return
                L2ContractHelper.computeCreate2Address(
                    address(this),
                    accountSalt,
                    bytes32(0x0100002f564d6017603b63f3adc01ad4c4367e355ef47d34a07a06ea98359c18),
                    keccak256(
                        abi.encode(
                            emailAuthImplementation(),
                            abi.encodeCall(
                                EmailAuth.initialize,
                                (recoveredAccount, accountSalt, address(this))
                            )
                        )
                    )
                );
        // } else {
        //     return
        //         Create2.computeAddress(
        //             accountSalt,
        //             keccak256(
        //                 abi.encodePacked(
        //                     type(ERC1967Proxy).creationCode,
        //                     abi.encode(
        //                         emailAuthImplementation(),
        //                         abi.encodeCall(
        //                             EmailAuth.initialize,
        //                             (recoveredAccount, accountSalt, address(this))
        //                         )
        //                     )
        //                 )
        //             )
        //         );
        // }
    }

    function deployProxy(address recoveredAccount, bytes32 accountSalt) public returns (address) {
        (bool success, bytes memory returnData) = SystemContractsCaller
            .systemCallWithReturndata(
                uint32(gasleft()),
                address(DEPLOYER_SYSTEM_CONTRACT),
            uint128(0),
            abi.encodeCall(
                DEPLOYER_SYSTEM_CONTRACT.create2,
                (
                    accountSalt,
                    proxyBytecodeHash,
                    abi.encode(
                                emailAuthImplementation(),
                                abi.encodeCall(
                                    EmailAuth.initialize,
                                    (
                                recoveredAccount,
                                accountSalt,
                                address(this)
                            )
                        )
                    )
                )
            )
        );
        address payable proxyAddress = abi.decode(returnData, (address));
        // ERC1967Proxy proxy = ERC1967Proxy(proxyAddress);
        // guardianEmailAuth = EmailAuth(address(proxy));
        return address(proxyAddress);
    }
}