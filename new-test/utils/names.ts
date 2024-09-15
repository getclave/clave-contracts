/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */

export const CONTRACT_NAMES = {
    BATCH_CALLER: 'BatchCaller',
    REGISTRY: 'ClaveRegistry',
    IMPLEMENTATION: 'ClaveImplementation',
    PROXY: 'ClaveProxy',
    FACTORY: 'AccountFactory',
    MOCK_VALIDATOR: 'MockValidator',
};

export enum VALIDATORS {
    MOCK = 'MockValidator',
    TEE = 'TEEValidator',
    EOA = 'EOAValidator',
    PASSKEY = 'PasskeyValidator',
}

export enum HOOKS {
    VALIDATION = 1,
    EXECUTION = 0,
}

export enum PAYMASTERS {
    GASLESS = 'GaslessPaymaster',
    ERC20 = 'ERC20Paymaster',
    ERC20_MOCK = 'ERC20PaymasterMock',
}
