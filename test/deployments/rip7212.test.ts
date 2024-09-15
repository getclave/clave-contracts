/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import { expect } from 'chai';
import * as hre from 'hardhat';
import { Provider } from 'zksync-ethers';

describe('RIP-7212 tests', () => {
    let provider: Provider;

    before(async () => {
        provider = new Provider(hre.network.config.url, undefined, {
            cacheTimeout: -1,
        });
    });

    it('should enable rip-7212', async () => {
        const precompileAddress = '0x0000000000000000000000000000000000000100';
        const data =
            '0x4cee90eb86eaa050036147a12d49004b6b9c72bd725d39d4785011fe190f0b4da73bd4903f0ce3b639bbbf6e8e80d16931ff4bcf5993d58468e8fb19086e8cac36dbcd03009df8c59286b162af3bd7fcc0450c9aa81be5d10d312af6c66b1d604aebd3099c618202fcfe16ae7770b0c49ab5eadf74b754204a3bb6060e44eff37618b065f9832de4ca6ca971a7a1adc826d0f7c00181a5fb2ddf79ae00b4e10e';

        const result = await provider.call({
            to: precompileAddress,
            data: data,
            value: 0,
        });

        expect(result).to.be.eq(
            '0x0000000000000000000000000000000000000000000000000000000000000001',
        );
    });
});
