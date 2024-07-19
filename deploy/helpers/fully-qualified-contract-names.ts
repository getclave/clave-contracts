/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
export const contractNames = {
    batchCaller: 'contracts/batch/BatchCaller.sol:BatchCaller',
    implementation: 'contracts/ClaveImplementation.sol:ClaveImplementation',
    factory: 'contracts/AccountFactory.sol:AccountFactory',
    mockValidator: 'contracts/test/MockValidator.sol:MockValidator',
    teeValidator:
        'contracts/validators/TEEValidatorConstant.sol:TEEValidatorConstant',
    passkeyValidator:
        'contracts/validators/PasskeyValidator.sol:PasskeyValidator',
    account: 'contracts/ClaveProxy.sol:ClaveProxy',
    registry: 'contracts/ClaveRegistry.sol:ClaveRegistry',
    socialRecovery:
        'contracts/modules/recovery/SocialRecoveryModule.sol:SocialRecoveryModule',
    cloudRecovery:
        'contracts/modules/recovery/CloudRecoveryModule.sol:CloudRecoveryModule',
    erc20Paymaster: 'contracts/paymasters/ERC20Paymaster.sol:ERC20Paymaster',
    erc20PaymasterMock:
        'contracts/test/ERC20PaymasterMock.sol:ERC20PaymasterMock',
    gaslessPaymaster:
        'contracts/paymasters/GaslessPaymaster.sol:GaslessPaymaster',
    koiEarnRouter: 'contracts/earn/KoiEarnRouter.sol:KoiEarnRouter',
    syncEarnRouter: 'contracts/earn/SyncEarnRouter.sol:SyncEarnRouter',
    syncEarnRouterV2: 'contracts/earn/SyncEarnRouter.sol:SyncEarnRouterV2',
    smoothieStore: 'contracts/berlin/SmoothieStore.sol:SmoothieStore',
    ZtaKe: 'contracts/earn/ZtaKe.sol:ZtaKe',
};
