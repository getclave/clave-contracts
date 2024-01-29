/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import '@matterlabs/hardhat-zksync-toolbox';
import '@nomicfoundation/hardhat-ethers';
import '@typechain/hardhat';
import dotenv from 'dotenv';
import type { HardhatUserConfig } from 'hardhat/config';
import type { NetworkUserConfig } from 'hardhat/types';

dotenv.config();

// dynamically changes endpoints for local tests
const zkSyncTestnet: NetworkUserConfig =
    process.env.NODE_ENV == 'test' || process.env.NODE_ENV == 'snapshot'
        ? {
              url: 'http://127.0.0.1:8011',
              ethNetwork: 'http://127.0.0.1:8545',
              zksync: true,
          }
        : {
              url: 'https://mainnet.era.zksync.io',
              ethNetwork: 'mainnet',
              zksync: true,
              // contract verification endpoint
              verifyURL:
                  'https://zksync2-mainnet-explorer.zksync.io/contract_verification',
              chainId: 324,
          };

const config: HardhatUserConfig = {
    zksolc: {
        version: 'latest',
        settings: {
            isSystem: true,
            optimizer: {
                fallbackToOptimizingForSize: false,
            },
        },
    },
    defaultNetwork: 'zkSyncTestnet',
    networks: {
        hardhat: {
            zksync: false,
        },
        zkSyncTestnet,
    },
    solidity: {
        compilers: [{ version: '0.8.17' }],
    },
};

export default config;
