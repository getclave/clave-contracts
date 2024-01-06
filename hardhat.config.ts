/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import '@matterlabs/hardhat-zksync-toolbox';
import '@nomiclabs/hardhat-ethers';
import '@typechain/hardhat';
import dotenv from 'dotenv';
import type { HardhatUserConfig } from 'hardhat/config';

dotenv.config();

// dynamically changes endpoints for local tests
const zkSyncTestnet =
    process.env.NODE_ENV == 'test' || process.env.NODE_ENV == 'snapshot'
        ? {
              url: 'http://127.0.0.1:8011',
              ethNetwork: 'http://127.0.0.1:8545',
              zksync: true,
          }
        : {
              url: 'https://zksync2-testnet.zksync.dev',
              ethNetwork: 'goerli',
              zksync: true,
              // contract verification endpoint
              verifyURL:
                  'https://zksync2-testnet-explorer.zksync.dev/contract_verification',
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
        // using different compiler version for separate contracts
        // overrides: {
        //     'contracts/path/contract.sol': {
        //         version: '0.8.21',
        //         settings: {},
        //     },
        // },
    },
    paths: {
        //comment this line when running scripts or compiling, uncomment when writing code
        //root: './apps/clave-contracts',
    },
};

export default config;
