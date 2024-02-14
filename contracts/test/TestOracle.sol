// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {PrimaryProdDataServiceConsumerBase} from '@redstone-finance/evm-connector/contracts/data-services/PrimaryProdDataServiceConsumerBase.sol';

/**
 * @title TestOracle - Test contract to simulate an oracle
 */
contract TestOracle is PrimaryProdDataServiceConsumerBase {
    // The nominator used for price calculation
    uint256 constant PRICE_PAIR_NOMINATOR = 1e18;
    uint256 public rateCheck;

    /**
     * @notice This function gets the ETH/PARAM_TOKEN price from the oracle
     */
    function getPairPrice(bytes memory oracleCalldata) external {
        bytes32 dataFeedIds = bytes32('ETH');
        rateCheck = callOracle(dataFeedIds, oracleCalldata);
    }

    /**
     * @notice This function calls the oracle and returns the values
     * @param dataFeedIds bytes32[] - Array of oracle ids
     * @param  - bytes              - Oracle payload
     * @return uint256[] - Oracle return as token prices
     */
    function callOracle(
        bytes32 dataFeedIds,
        bytes memory //* oracleCalldata */
    ) private view returns (uint256) {
        return getOracleNumericValueFromTxMsg(dataFeedIds);
    }
}
