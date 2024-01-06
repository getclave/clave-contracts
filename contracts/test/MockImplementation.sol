// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {MockStorage} from './MockStorage.sol';
import {AddressLinkedList} from '../libraries/LinkedList.sol';

contract MockImplementation {
    using AddressLinkedList for mapping(address => address);

    bytes32 private constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setTestNumber(uint256 number) external {
        MockStorage.layout().testNumber = number;
    }

    function getTestNumber() external view returns (uint256) {
        return MockStorage.layout().testNumber;
    }

    function r1IsValidator(address validator) external view returns (bool) {
        return _r1IsValidator(validator);
    }

    function r1ListValidators() external view returns (address[] memory validatorList) {
        validatorList = _r1ValidatorsLinkedList().list();
    }

    function implementation() external view returns (address) {
        address impl;
        assembly {
            impl := and(sload(_IMPLEMENTATION_SLOT), 0xffffffffffffffffffffffffffffffffffffffff)
        }

        return impl;
    }

    function _r1IsValidator(address validator) internal view returns (bool) {
        return _r1ValidatorsLinkedList().exists(validator);
    }

    function _r1ValidatorsLinkedList()
        private
        view
        returns (mapping(address => address) storage r1Validators)
    {
        r1Validators = MockStorage.layout().r1Validators;
    }
}
