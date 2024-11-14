// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

library Errors {
    /*//////////////////////////////////////////////////////////////
                               CLAVE
    //////////////////////////////////////////////////////////////*/

    error INSUFFICIENT_FUNDS(); // 0xe7931438
    error FEE_PAYMENT_FAILED(); // 0x3d40a3a3
    error UNAUTHORIZED_OUTSIDE_TRANSACTION(); // 0xfc82da4e
    error VALIDATION_HOOK_FAILED(); // 0x52c9d27a

    /*//////////////////////////////////////////////////////////////
                               LINKED LIST
    //////////////////////////////////////////////////////////////*/

    error INVALID_PREV(); // 0x5a4c0eb3
    // Bytes
    error INVALID_BYTES(); // 0xb6dfaaff
    error BYTES_ALREADY_EXISTS(); // 0xdf6cac6b
    error BYTES_NOT_EXISTS(); // 0x689908a6
    // Address
    error INVALID_ADDRESS(); // 0x5963709b
    error ADDRESS_ALREADY_EXISTS(); // 0xf2d4d191
    error ADDRESS_NOT_EXISTS(); // 0xad6ab975

    /*//////////////////////////////////////////////////////////////
                              OWNER MANAGER
    //////////////////////////////////////////////////////////////*/

    error EMPTY_R1_OWNERS(); // 0x2a480544
    error INVALID_PUBKEY_LENGTH(); // 0x04c4d8f7

    /*//////////////////////////////////////////////////////////////
                             VALIDATOR MANAGER
    //////////////////////////////////////////////////////////////*/

    error EMPTY_R1_VALIDATORS(); // 0xee4886b6
    error VALIDATOR_ERC165_FAIL(); // 0x5d5273ad

    /*//////////////////////////////////////////////////////////////
                              UPGRADE MANAGER
    //////////////////////////////////////////////////////////////*/

    error SAME_IMPLEMENTATION(); // 0x5e741005

    /*//////////////////////////////////////////////////////////////
                              HOOK MANAGER
    //////////////////////////////////////////////////////////////*/

    error EMPTY_HOOK_ADDRESS(); // 0x413348ae
    error HOOK_ERC165_FAIL(); // 0x9f93f87d
    error INVALID_KEY(); // 0xce7045bd

    /*//////////////////////////////////////////////////////////////
                             MODULE MANAGER
    //////////////////////////////////////////////////////////////*/

    error EMPTY_MODULE_ADDRESS(); // 0x912fe2f2
    error RECUSIVE_MODULE_CALL(); // 0x2cf7b9c8
    error MODULE_ERC165_FAIL(); // 0xc1ad2a50

    /*//////////////////////////////////////////////////////////////
                              AUTH
    //////////////////////////////////////////////////////////////*/

    error NOT_FROM_BOOTLOADER(); // 0x93887e3b
    error NOT_FROM_MODULE(); // 0x574a805d
    error NOT_FROM_HOOK(); // 0xd675a4f1
    error NOT_FROM_SELF(); // 0xa70c28d1
    error NOT_FROM_SELF_OR_MODULE(); // 0x22a1259f

    /*//////////////////////////////////////////////////////////////
                            R1 VALIDATOR
    //////////////////////////////////////////////////////////////*/

    error INVALID_SIGNATURE(); // 0xa3402a38

    /*//////////////////////////////////////////////////////////////
                          SOCIAL RECOVERY
    //////////////////////////////////////////////////////////////*/

    error INVALID_RECOVERY_CONFIG(); // 0xf774f439
    error INVALID_RECOVERY_NONCE(); // 0x098c9f8e
    error INVALID_GUARDIAN(); // 0x11a2a82b
    error INVALID_GUARDIAN_SIGNATURE(); // 0xcc117c1c
    error ZERO_ADDRESS_GUARDIAN(); // 0x6de9b401
    error GUARDIANS_MUST_BE_SORTED(); // 0xc52b41f7
    error RECOVERY_TIMELOCK(); // 0x1506ac5a
    error RECOVERY_NOT_STARTED(); // 0xa6a4a3aa
    error RECOVERY_NOT_INITED(); // 0xd0f6fdbf
    error RECOVERY_IN_PROGRESS(); // 0x8daa42a9
    error INSUFFICIENT_GUARDIANS(); // 0x7629075d
    error ALREADY_INITED(); // 0xdb0c77c8

    /*//////////////////////////////////////////////////////////////
                            FACTORY
    //////////////////////////////////////////////////////////////*/

    error DEPLOYMENT_FAILED(); // 0x0f02d218
    error INITIALIZATION_FAILED(); // 0x5b101091

    /*//////////////////////////////////////////////////////////////
                            PAYMASTER
    //////////////////////////////////////////////////////////////*/

    error UNSUPPORTED_FLOW(); // 0xd721e389
    error UNAUTHORIZED_WITHDRAW(); // 0x7809a0b4
    error INVALID_TOKEN(); // 0xd0995cf2
    error SHORT_PAYMASTER_INPUT(); // 0x48d170f6
    error UNSUPPORTED_TOKEN(); // 0xce706f70
    error LESS_ALLOWANCE_FOR_PAYMASTER(); // 0x11f7d13f
    error FAILED_FEE_TRANSFER(); // 0xf316e09d
    error INVALID_MARKUP(); // 0x4af7ffe3
    error USER_LIMIT_REACHED(); // 0x07235346
    error INVALID_USER_LIMIT(); // 0x2640fa41
    error NOT_CLAVE_ACCOUNT(); // 0x81566ee0
    error EXCEEDS_MAX_SPONSORED_ETH(); // 0x3f379f40

    /*//////////////////////////////////////////////////////////////
                             REGISTRY
    //////////////////////////////////////////////////////////////*/

    error NOT_FROM_FACTORY(); // 0x238438ed
    error NOT_FROM_DEPLOYER(); // 0x83f090e3

    /*//////////////////////////////////////////////////////////////
                            BatchCaller
    //////////////////////////////////////////////////////////////*/

    error ONLY_DELEGATECALL(); // 0x43d22ee9
    error CALL_FAILED(); // 0x84aed38d

    /*//////////////////////////////////////////////////////////////
                            INITABLE
    //////////////////////////////////////////////////////////////*/

    error MODULE_NOT_ADDED_CORRECTLY(); // 0xb66e8ec4
    error MODULE_NOT_REMOVED_CORRECTLY(); // 0x680c8744
}
