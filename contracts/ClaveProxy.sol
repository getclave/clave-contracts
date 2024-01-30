// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {EfficientCall} from '@matterlabs/zksync-contracts/l2/system-contracts/libraries/EfficientCall.sol';

contract ClaveProxy {
    //keccak-256 of "eip1967.proxy.implementation" subtracted by 1
    bytes32 private constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice Sets the initial implementation contract.
     * @param implementation address - Address of the implementation contract.
     */
    constructor(address implementation) {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementation)
        }
    }

    /**
     * @dev Fallback function that delegates the call to the implementation contract.
     */
    fallback() external payable {
        address impl;
        assembly {
            impl := and(sload(_IMPLEMENTATION_SLOT), 0xffffffffffffffffffffffffffffffffffffffff)
        }

        bool success = EfficientCall.rawDelegateCall(gasleft(), impl, msg.data);

        assembly {
            returndatacopy(0, 0, returndatasize())
            switch success
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
