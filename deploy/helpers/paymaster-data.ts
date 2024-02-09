/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { parseEther } from 'ethers';

export const paymasterData = {
    // ERC20Paymaster, GaslessPaymaster
    deploys: [false, true],
    fund: [parseEther('0'), parseEther('0')],
    // GaslessPaymaster free tx limit
    gaslessPaymaster_txLimit: 5,
    // ERC20Paymaster token inputs
    tokenInput: [
        {
            tokenAddress: '0x3355df6d4c9c3035724fd0e3914de96a5a83aaf4',
            decimals: 6,
            priceMarkup: 11_000,
        },
        {
            tokenAddress: '0x493257fd37edb34451f62edf8d2a0c418852ba4c',
            decimals: 6,
            priceMarkup: 11_000,
        },
        {
            tokenAddress: '0x4b9eb6c0b6ea15176bbf62841c6b2a8a398cb656',
            decimals: 18,
            priceMarkup: 11_000,
        },
    ],
};
