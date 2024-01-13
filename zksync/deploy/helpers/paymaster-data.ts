/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { parseEther } from 'ethers';

export const paymasterData = {
    // ERC20Paymaster, GaslessPaymaster
    deploys: [true, false],
    fund: [parseEther('0.2'), parseEther('1')],
    // GaslessPaymaster free tx limit
    gaslessPaymaster_txLimit: 20000,
    // ERC20Paymaster token inputs
    tokenInput: [
        {
            tokenAddress: '0x0faF6df7054946141266420b43783387A78d82A9',
            decimals: 6,
            priceMarkup: 11_000,
        },
        {
            tokenAddress: '0x3e7676937A7E96CFB7616f255b9AD9FF47363D4b',
            decimals: 18,
            priceMarkup: 11_000,
        },
    ],
};
