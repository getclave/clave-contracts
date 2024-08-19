/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.17;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.25;

////import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * A struct representing the values required for a guardian
 */
struct GuardianStorage {
    GuardianStatus status;
    uint256 weight;
}

/**
 * An enum representing the possible status of a guardian
 * The default status is NONE status. It should be REQUESTED
 * when adding a guardian before the guardian has accepted.
 * Once the guardian has accepted, the status should be ACCEPTED.
 */
enum GuardianStatus {
    NONE,
    REQUESTED,
    ACCEPTED
}

/**
 * Enumerable Map library based on Open Zeppelin's EnumerableMap library.
 * Modified to map from an address to a custom struct: GuardianStorage
 *
 * All functions have been modified to support mapping to the GuardianStorage
 * struct. Any additional modifications are documented in the natspec for
 * each function
 */
library EnumerableGuardianMap {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * Maximum number of guardians that can be added
     */
    uint256 public constant MAX_NUMBER_OF_GUARDIANS = 32;

    error MaxNumberOfGuardiansReached();
    error TooManyValuesToRemove();

    struct AddressToGuardianMap {
        // Storage of keys
        EnumerableSet.AddressSet _keys;
        mapping(address key => GuardianStorage) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     *
     * @custom:modification Modifed from the OpenZeppelin implementation to support a max number of
     * guardians.
     * This prevents the library having unbounded costs when clearing up state
     */
    function set(
        AddressToGuardianMap storage map,
        address key,
        GuardianStorage memory value
    ) internal returns (bool) {
        map._values[key] = value;
        bool success = map._keys.add(key);

        uint256 length = map._keys.length();
        if (success && length > MAX_NUMBER_OF_GUARDIANS) {
            revert MaxNumberOfGuardiansReached();
        }
        return success;
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToGuardianMap storage map, address key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Removes all key-value pairs from a map. O(n) where n <= 32
     *
     * @custom:modification This is a new function that did not exist on the
     * original Open Zeppelin library.
     */
    function removeAll(AddressToGuardianMap storage map, address[] memory guardianKeys) internal {
        if (guardianKeys.length > MAX_NUMBER_OF_GUARDIANS) {
            revert TooManyValuesToRemove();
        }
        for (uint256 i = 0; i < guardianKeys.length; i++) {
            delete map._values[guardianKeys[i]];
            map._keys.remove(guardianKeys[i]);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map
     *
     * @custom:modification The original
     * Open Zeppelin implementation threw an error if the value
     * could not be found. This implementation behaves as if you
     * were retrieving a value from an actual mapping i.e. returns
     * default solidity values
     */
    function get(
        AddressToGuardianMap storage map,
        address key
    ) internal view returns (GuardianStorage memory) {
        return map._values[key];
    }

    /**
     * @dev Return an array containing all the keys. O(n) where n <= 32
     *
     * WARNING: This operation will copy the entire storage to memory, which could
     * be quite expensive.
     */
    function keys(AddressToGuardianMap storage map) internal view returns (address[] memory) {
        return map._keys.values();
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.25;

interface IGuardianManager {
    /**
     * A struct representing the values required for guardian configuration
     * Config should be maintained over subsequent recovery attempts unless explicitly modified
     */
    struct GuardianConfig {
        uint256 guardianCount; // total count for all guardians
        uint256 totalWeight; // combined weight for all guardians. ////Important for checking that
        // thresholds are valid.
        uint256 acceptedWeight; // combined weight for all accepted guardians. This is separated
        // from totalWeight as it is ////important to prevent recovery starting without enough
        // accepted guardians to meet the threshold. Storing this in a variable avoids the need
        // to loop over accepted guardians whenever checking if a recovery attempt can be
        // started without being broken
        uint256 threshold; // the threshold required to successfully process a recovery attempt
    }

    event AddedGuardian(address indexed account, address indexed guardian, uint256 weight);
    event GuardianStatusUpdated(
        address indexed account,
        address indexed guardian,
        GuardianStatus newStatus
    );
    event RemovedGuardian(address indexed account, address indexed guardian, uint256 weight);
    event ChangedThreshold(address indexed account, uint256 threshold);

    error RecoveryInProcess();
    error IncorrectNumberOfWeights(uint256 guardianCount, uint256 weightCount);
    error ThresholdCannotBeZero();
    error InvalidGuardianAddress(address guardian);
    error InvalidGuardianWeight();
    error AddressAlreadyGuardian();
    error ThresholdExceedsTotalWeight(uint256 threshold, uint256 totalWeight);
    error StatusCannotBeTheSame(GuardianStatus newStatus);
    error SetupNotCalled();
    error AddressNotGuardianForAccount();

    function getGuardianConfig(address account) external view returns (GuardianConfig memory);

    function getGuardian(
        address account,
        address guardian
    ) external view returns (GuardianStorage memory);

    function addGuardian(address guardian, uint256 weight) external;

    function removeGuardian(address guardian) external;

    function changeThreshold(uint256 threshold) external;
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.25;

////import { GuardianStorage, GuardianStatus } from "../libraries/EnumerableGuardianMap.sol";

interface IEmailRecoveryManager {
    /*//////////////////////////////////////////////////////////////////////////
                                TYPE DELARATIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * A struct representing the values required for recovery configuration
     * Config should be maintained over subsequent recovery attempts unless explicitly modified
     */
    struct RecoveryConfig {
        uint256 delay; // the time from when recovery is started until the recovery request can be
        // executed
        uint256 expiry; // the time from when recovery is started until the recovery request becomes
        // invalid. The recovery expiry encourages the timely execution of successful recovery
        // attempts, and reduces the risk of unauthorized access through stale or outdated
        // requests.
    }

    /**
     * A struct representing the values required for a recovery request
     * The request state should be maintained over a single recovery attempts unless
     * explicitly modified. It should be deleted after a recovery attempt has been processed
     */
    struct RecoveryRequest {
        uint256 executeAfter; // the timestamp from which the recovery request can be executed
        uint256 executeBefore; // the timestamp from which the recovery request becomes invalid
        uint256 currentWeight; // total weight of all guardian approvals for the recovery request
        bytes32 calldataHash; // the keccak256 hash of the calldata used to execute the
        // recovery attempt
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event RecoveryConfigured(
        address indexed account,
        uint256 guardianCount,
        uint256 totalWeight,
        uint256 threshold
    );
    event RecoveryConfigUpdated(address indexed account, uint256 delay, uint256 expiry);
    event GuardianAccepted(address indexed account, address indexed guardian);
    event RecoveryProcessed(
        address indexed account,
        address indexed guardian,
        uint256 executeAfter,
        uint256 executeBefore,
        bytes32 calldataHash
    );
    event RecoveryCompleted(address indexed account);
    event RecoveryCancelled(address indexed account);
    event RecoveryDeInitialized(address indexed account);

    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    error InvalidVerifier();
    error InvalidDkimRegistry();
    error InvalidEmailAuthImpl();
    error InvalidSubjectHandler();
    error SetupAlreadyCalled();
    error AccountNotConfigured();
    error DelayMoreThanExpiry(uint256 delay, uint256 expiry);
    error RecoveryWindowTooShort(uint256 recoveryWindow);
    error ThresholdExceedsAcceptedWeight(uint256 threshold, uint256 acceptedWeight);
    error InvalidGuardianStatus(
        GuardianStatus guardianStatus,
        GuardianStatus expectedGuardianStatus
    );
    error InvalidAccountAddress();
    error NoRecoveryConfigured();
    error NotEnoughApprovals(uint256 currentWeight, uint256 threshold);
    error DelayNotPassed(uint256 blockTimestamp, uint256 executeAfter);
    error RecoveryRequestExpired(uint256 blockTimestamp, uint256 executeBefore);
    error InvalidCalldataHash(bytes32 calldataHash, bytes32 expectedCalldataHash);
    error NoRecoveryInProcess();

    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getRecoveryConfig(address account) external view returns (RecoveryConfig memory);

    function getRecoveryRequest(address account) external view returns (RecoveryRequest memory);

    function updateRecoveryConfig(RecoveryConfig calldata recoveryConfig) external;

    function cancelRecovery() external;
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}('');
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata
    ) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {UpgradeableBeacon} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.20;

////import {IBeacon} from "../beacon/IBeacon.sol";
////import {Address} from "../../utils/Address.sol";
////import {StorageSlot} from "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 */
library ERC1967Utils {
    // We re-declare ERC-1967 events here because they can't be used directly from IERC1967.
    // This will be fixed in Solidity 0.8.21. At that point we should remove these events.
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev The `admin` of the proxy is invalid.
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {IERC1967-AdminChanged} event.
     */
    function changeAdmin(address newAdmin) internal {
        emit AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev Change the beacon and trigger a setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-BeaconUpgraded} event.
     *
     * CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
     * it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
     * efficiency.
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Proxy.sol)

pragma solidity ^0.8.20;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback
     * function and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE =
        0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

////import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.20;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * ////IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

////import {Math} from "./math/Math.sol";
////import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = '0123456789abcdef';
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? '-' : '', toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed,
        uint256 tokenId
    );

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

////import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.9;

////import "@openzeppelin/contracts/utils/Strings.sol";

/// @title DecimalUtils
/// @notice DecimalUtils library for converting uint256 to string with decimal places
library DecimalUtils {
    /// @notice Convert uint256 to human readable string with decimal places
    /// @param value uint256 value to convert
    /// @return string representation of value with decimal places
    function uintToDecimalString(uint256 value) internal pure returns (string memory) {
        return uintToDecimalString(value, 18);
    }

    /// @notice Convert uint256 to human readable string with decimal places
    /// @param value uint256 value to convert
    /// @param decimal number of decimal places
    /// @return string representation of value with decimal places
    function uintToDecimalString(
        uint256 value,
        uint decimal
    ) internal pure returns (string memory) {
        // Convert value to string in wei format (no decimals)
        bytes memory valueBytes = bytes(Strings.toString(value));
        uint8 valueLength = uint8(valueBytes.length);

        // Create result array with max length
        // If less than 18 decimals, then 2 extra for "0.", otherwise one extra for "."
        bytes memory result = new bytes(valueLength > decimal ? valueLength + 1 : decimal + 2);
        uint8 resultLength = uint8(result.length);

        // We will be populating result array by copying from value array from last to first index
        // Difference between result and value array index when copying
        // If more than 18, then 1 index diff for ".", otherwise actual diff in length
        uint delta = valueLength > decimal ? 1 : resultLength - valueLength;

        // Boolean to indicate if we found a non-zero digit when scanning from last to first index
        bool foundNonZeroDecimal;

        uint8 actualResultLen = 0;

        // In each iteration we fill one index of result array (starting from end)
        for (uint8 i = resultLength - 1; i >= 0; i--) {
            // Check if we have reached the index where we need to add decimal point
            if (i == resultLength - decimal - 1) {
                // No need to add "." if there was no value in decimal places
                if (foundNonZeroDecimal) {
                    result[i] = '.';
                    actualResultLen++;
                }
                // Set delta to 0, as we have already added decimal point (only for valueLength > 18)
                delta = 0;
            }
            // If valueLength < 18 and we have copied everything, fill zeros
            else if (valueLength <= decimal && i < resultLength - valueLength) {
                result[i] = '0';
                actualResultLen++;
            }
            // If non-zero decimal is found, or decimal point inserted (delta == 0), copy from value array
            else if (foundNonZeroDecimal || delta == 0) {
                result[i] = valueBytes[i - delta];
                actualResultLen++;
            }
            // If we find non-zero decumal for the first time (trailing zeros are skipped)
            else if (valueBytes[i - delta] != '0') {
                result[i] = valueBytes[i - delta];
                actualResultLen++;
                foundNonZeroDecimal = true;
            }

            // To prevent the last i-- underflow
            if (i == 0) {
                break;
            }
        }

        // Create final result array with correct length
        bytes memory compactResult = new bytes(actualResultLen);
        for (uint8 i = 0; i < actualResultLen; i++) {
            compactResult[i] = result[i];
        }

        return string(compactResult);
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

////import {IERC20} from "./IERC20.sol";
////import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
////import {Context} from "../../utils/Context.sol";
////import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax =
        20491192805390485299153009773594534940189261866228447918068658471970481763042;
    uint256 constant alphay =
        9383485363053290200918347156157836566562967994039712273449902621266178545958;
    uint256 constant betax1 =
        4252822878758300859123897981450591353533073413197771768651442665752259397132;
    uint256 constant betax2 =
        6375614351688725206403948262868962793625744043794305715222011528459656738731;
    uint256 constant betay1 =
        21847035105528745403288232691147584728191162732299865338377159692350059136679;
    uint256 constant betay2 =
        10505242626370262277552901082094356697409835680220590971873171140371331206856;
    uint256 constant gammax1 =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 =
        4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 =
        8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 =
        12348375662783824431360707906202475009449369812921990201376235771680861701966;
    uint256 constant deltax2 =
        1390621091717691233659791897033569945783127756008503250856151404215287127098;
    uint256 constant deltay1 =
        21545653682963288007472972452138234474169143155774752223643789231933860474340;
    uint256 constant deltay2 =
        10610549897370405036411988417557836327116891506639515374316821127902275605593;

    uint256 constant IC0x =
        5901406458595327327953646561359621442218448144107991955344827840671354857930;
    uint256 constant IC0y =
        21253883398616811363937453025480398551698716152192802899988370991179418894921;

    uint256 constant IC1x =
        1112924942971302135990579038492068551965379862222416146684206705079782572000;
    uint256 constant IC1y =
        6845816202276549205403237603547410855545803354942552863847676397548741086071;

    uint256 constant IC2x =
        14146397086704743317768846126489596483634956428235300380826232977310804058751;
    uint256 constant IC2y =
        19618883007025739156467626277666586024401705866552606313791444982720962403992;

    uint256 constant IC3x =
        3901572409202614942721645284047738923242593674037512752046910139604415193490;
    uint256 constant IC3y =
        20492449392704526941468738279820790768424887146903635663987211396806301809154;

    uint256 constant IC4x =
        18540181064351079043471661082110994395960833330341135578479476830087776228683;
    uint256 constant IC4y =
        11176005255132390129621080493002450161350701375862520723126575901394028996036;

    uint256 constant IC5x =
        19561918792572579721654605669351975749853953476158354443105355794367963998057;
    uint256 constant IC5y =
        8218678694141104830016990002861269810060858478661593498963178088127632633272;

    uint256 constant IC6x =
        9430924798221081020093287735191121193795036835461664479209198319741867653703;
    uint256 constant IC6y =
        8320455794218847878770580093897658145962468495286236900439725456006531945699;

    uint256 constant IC7x =
        5026847283727041400632489144741052290976729570767028644525050581059876916251;
    uint256 constant IC7y =
        18709603090338372683001965035561848282369713676288357172691730209331905334650;

    uint256 constant IC8x =
        17783950150020738154914534833285662833687830065154708170534593149023190841571;
    uint256 constant IC8y =
        6711670108831861054349992265875143708175087706665287716580642850559233815182;

    uint256 constant IC9x =
        6456809683101221239825536925658971026995917443342977471616457395354933010826;
    uint256 constant IC9y =
        2014292748365982904981992383163603273504856743882959093701478470668783800522;

    uint256 constant IC10x =
        6628245325000975286546535223213930648454767286000819266622720989919128655736;
    uint256 constant IC10y =
        14513751619334179776611945559238333965209884013883320491822197554011245102668;

    uint256 constant IC11x =
        18570424159211943648550772570282559547250130191621494465657111355378707354500;
    uint256 constant IC11y =
        3142881938352899028782850032628554749777583832256141371247984173352247988131;

    uint256 constant IC12x =
        5223991002378260090449510454796281831282905631623677469960113091483024319301;
    uint256 constant IC12y =
        9427018011817145184335218137442223127741016816822775509206816206494077869941;

    uint256 constant IC13x =
        17733384847564503082934979078550596341075160377145956961996412508907155849602;
    uint256 constant IC13y =
        15345500273986785785979010183753446192836470842052033037545791683924216389909;

    uint256 constant IC14x =
        6541603162653988673614876540286498610416711433782997011446804048984497507717;
    uint256 constant IC14y =
        9471585496716317833911101487553454694761435169521054429602533117895220539092;

    uint256 constant IC15x =
        6574110840837190171512762164893486105535576711656029901056739039814628526912;
    uint256 constant IC15y =
        12107221022070295505274408663667253928323650746131661962928553805430682213730;

    uint256 constant IC16x =
        2983775925467162306639671044788352921278318217335490557023737802970494396161;
    uint256 constant IC16y =
        15155657642358487296835454918514213311356981076876734700573166757257484354564;

    uint256 constant IC17x =
        8967042914633055089306636825844718647849951037719728238537295360572488150548;
    uint256 constant IC17y =
        16316365584620447093615538375124020157614277415345119540410103156547686499616;

    uint256 constant IC18x =
        10539075382040152021577786214341262536565753081943101851679620745620126843721;
    uint256 constant IC18y =
        4734602432159888257161632785059762380496749946015675717019228118945872853040;

    uint256 constant IC19x =
        16904274081002162388173688128412241495718571792446724759784404749590000812400;
    uint256 constant IC19y =
        10801084318813806801902242112307629808119029411792686266329164737317751231217;

    uint256 constant IC20x =
        15575787937775277998941372228242544347460724933647624890935023166333401850163;
    uint256 constant IC20y =
        7296638718677056910701470329118855562874930285186351569007798599358833717218;

    uint256 constant IC21x =
        4551313941391400232712859196059035637265126775160423752556164701565012171961;
    uint256 constant IC21y =
        21401656423982733211718420214626338184514587667446979844631973864641456629261;

    uint256 constant IC22x =
        2935540066773152386094450378156329519379475479888931777862603161088003692041;
    uint256 constant IC22y =
        3754706265995206762948051647660125270465347882441656302776943004798594006627;

    uint256 constant IC23x =
        14941485327978437375521006241254634444037644973379906367567115351627139641414;
    uint256 constant IC23y =
        10702407562034274430221897944829443699402512693373259167588271091307663372710;

    uint256 constant IC24x =
        8275896680177260146907953439805305572759478043924598922328323793281943403370;
    uint256 constant IC24y =
        4247674182996730416195978445155055073549714994568066175487529509583649388873;

    uint256 constant IC25x =
        5689003246975774737588871342271076456426408075813318043434367952407244465697;
    uint256 constant IC25y =
        5331139184498747881817447962895230742876804067387026910085264060106931675015;

    uint256 constant IC26x =
        9133389296516422045582607363916275184958302548102626374643142889003044665947;
    uint256 constant IC26y =
        21212127989644328313744743046359043793974008456261367858588476558007302881330;

    uint256 constant IC27x =
        1846381662521291690941661313906009843371539776920831630929177290350683400816;
    uint256 constant IC27y =
        14037588365801936321970551415842797526891505906435930017587651178284699267713;

    uint256 constant IC28x =
        9781100104817210330466721014252420484088695894046800561845749556748658092046;
    uint256 constant IC28y =
        5247283488585909287681175111965979900241094426050812131890410213638115643151;

    uint256 constant IC29x =
        2601884709396729070900092103586635418201773412881087270429648554918650589212;
    uint256 constant IC29y =
        9908981325212548797939830108274909156521241172863051558205007650971279318517;

    uint256 constant IC30x =
        9939266818987304280716292846681442246091197219658249578844451051169120630547;
    uint256 constant IC30y =
        2572015044563341438903424542575536095020061887469225890988354903901552937232;

    uint256 constant IC31x =
        13118893670705126645185968274218628155008227884751114852720068135196260630881;
    uint256 constant IC31y =
        6230722867526865558981774022287077378574474669760549030286133277816703673143;

    uint256 constant IC32x =
        17212407207955414163237618089196466668701707894128397707051726962337098549169;
    uint256 constant IC32y =
        8404846513505663468605283225980364311579458231305844344066234966448248022846;

    uint256 constant IC33x =
        11738484603497709502459820489878480711987723990943728339865918189223648597498;
    uint256 constant IC33y =
        4876663067150136827802187921986818211983158246723787276826534383019800886864;

    uint256 constant IC34x =
        10388736566666345681097260475847864743327046424517259125467497894377198799740;
    uint256 constant IC34y =
        18058504066267363666256588143336895545386092144245446448007719752461244713629;

    // For zksync mainnet TODO: Current addresses are on zkSync sepolia,
    // Please deploy them before you deploy the Groth16Verifier.
    address constant ecAddAddrZkSync = 0x4cc3aa31951FADa114cBAd54686E2A082Df6C4fa;
    address constant ecMulAddrZkSync = 0x2abE798291c05B054475BDEB017161737A6A1b4F;
    address constant ecPairingAddrZkSync = 0x9F7D2961D2E522D5B1407dD1e364A520DdC8a77F;
    // For zksync sepolia
    address constant ecAddAddrZkSyncSepolia = 0x4cc3aa31951FADa114cBAd54686E2A082Df6C4fa;
    address constant ecMulAddrZkSyncSepolia = 0x2abE798291c05B054475BDEB017161737A6A1b4F;
    address constant ecPairingAddrZkSyncSepolia = 0x9F7D2961D2E522D5B1407dD1e364A520DdC8a77F;

    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[34] calldata _pubSignals
    ) public view returns (bool) {
        uint16 zksync;
        if (block.chainid == 300) {
            zksync = 2; // zkSync sepolia
        } else if (block.chainid == 324) {
            zksync = 1; // zkSync mainnet
        } else {
            zksync = 0; // others
        }

        assembly {
            function checkField(v) {
                if iszero(lt(v, q)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s, z) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                switch z
                case 1 {
                    success := staticcall(sub(gas(), 2000), ecMulAddrZkSync, mIn, 96, mIn, 64)
                }
                case 2 {
                    success := staticcall(
                        sub(gas(), 2000),
                        ecMulAddrZkSyncSepolia,
                        mIn,
                        96,
                        mIn,
                        64
                    )
                }
                default {
                    success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)
                }

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                switch z
                case 1 {
                    success := staticcall(sub(gas(), 2000), ecAddAddrZkSync, mIn, 128, pR, 64)
                }
                case 2 {
                    success := staticcall(
                        sub(gas(), 2000),
                        ecAddAddrZkSyncSepolia,
                        mIn,
                        128,
                        pR,
                        64
                    )
                }
                default {
                    success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)
                }

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem, z) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x

                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)), z)

                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)), z)

                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)), z)

                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)), z)

                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)), z)

                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)), z)

                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)), z)

                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)), z)

                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)), z)

                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)), z)

                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)), z)

                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)), z)

                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)), z)

                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)), z)

                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)), z)

                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)), z)

                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)), z)

                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)), z)

                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)), z)

                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)), z)

                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)), z)

                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)), z)

                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)), z)

                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)), z)

                g1_mulAccC(_pVk, IC25x, IC25y, calldataload(add(pubSignals, 768)), z)

                g1_mulAccC(_pVk, IC26x, IC26y, calldataload(add(pubSignals, 800)), z)

                g1_mulAccC(_pVk, IC27x, IC27y, calldataload(add(pubSignals, 832)), z)

                g1_mulAccC(_pVk, IC28x, IC28y, calldataload(add(pubSignals, 864)), z)

                g1_mulAccC(_pVk, IC29x, IC29y, calldataload(add(pubSignals, 896)), z)

                g1_mulAccC(_pVk, IC30x, IC30y, calldataload(add(pubSignals, 928)), z)

                g1_mulAccC(_pVk, IC31x, IC31y, calldataload(add(pubSignals, 960)), z)

                g1_mulAccC(_pVk, IC32x, IC32y, calldataload(add(pubSignals, 992)), z)

                g1_mulAccC(_pVk, IC33x, IC33y, calldataload(add(pubSignals, 1024)), z)

                g1_mulAccC(_pVk, IC34x, IC34y, calldataload(add(pubSignals, 1056)), z)

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))

                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)

                let success := false
                switch z
                case 1 {
                    success := staticcall(
                        sub(gas(), 2000),
                        ecPairingAddrZkSync,
                        _pPairing,
                        768,
                        _pPairing,
                        0x20
                    )
                }
                case 2 {
                    success := staticcall(
                        sub(gas(), 2000),
                        ecPairingAddrZkSyncSepolia,
                        _pPairing,
                        768,
                        _pPairing,
                        0x20
                    )
                }
                default {
                    success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)
                }

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F

            checkField(calldataload(add(_pubSignals, 0)))

            checkField(calldataload(add(_pubSignals, 32)))

            checkField(calldataload(add(_pubSignals, 64)))

            checkField(calldataload(add(_pubSignals, 96)))

            checkField(calldataload(add(_pubSignals, 128)))

            checkField(calldataload(add(_pubSignals, 160)))

            checkField(calldataload(add(_pubSignals, 192)))

            checkField(calldataload(add(_pubSignals, 224)))

            checkField(calldataload(add(_pubSignals, 256)))

            checkField(calldataload(add(_pubSignals, 288)))

            checkField(calldataload(add(_pubSignals, 320)))

            checkField(calldataload(add(_pubSignals, 352)))

            checkField(calldataload(add(_pubSignals, 384)))

            checkField(calldataload(add(_pubSignals, 416)))

            checkField(calldataload(add(_pubSignals, 448)))

            checkField(calldataload(add(_pubSignals, 480)))

            checkField(calldataload(add(_pubSignals, 512)))

            checkField(calldataload(add(_pubSignals, 544)))

            checkField(calldataload(add(_pubSignals, 576)))

            checkField(calldataload(add(_pubSignals, 608)))

            checkField(calldataload(add(_pubSignals, 640)))

            checkField(calldataload(add(_pubSignals, 672)))

            checkField(calldataload(add(_pubSignals, 704)))

            checkField(calldataload(add(_pubSignals, 736)))

            checkField(calldataload(add(_pubSignals, 768)))

            checkField(calldataload(add(_pubSignals, 800)))

            checkField(calldataload(add(_pubSignals, 832)))

            checkField(calldataload(add(_pubSignals, 864)))

            checkField(calldataload(add(_pubSignals, 896)))

            checkField(calldataload(add(_pubSignals, 928)))

            checkField(calldataload(add(_pubSignals, 960)))

            checkField(calldataload(add(_pubSignals, 992)))

            checkField(calldataload(add(_pubSignals, 1024)))

            checkField(calldataload(add(_pubSignals, 1056)))

            checkField(calldataload(add(_pubSignals, 1088)))

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem, zksync)

            mstore(0, isValid)
            return(0, 0x20)
        }
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface IDKIMRegistry {
    function isDKIMPublicKeyHashValid(
        string memory domainName,
        bytes32 publicKeyHash
    ) external view returns (bool);
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

////import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

////import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
////import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation =
        0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.20;

////import {IERC1822Proxiable} from "../../interfaces/draft-IERC1822.sol";
////import {ERC1967Utils} from "../ERC1967/ERC1967Utils.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable __self = address(this);

    /**
     * @dev The version of the upgrade interface of the contract. If this getter is missing, both `upgradeTo(address)`
     * and `upgradeToAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
     * while `upgradeToAndCall` will invoke the `receive` function if the second argument is the empty byte string.
     * If the getter returns `"5.0.0"`, only `upgradeToAndCall(address,bytes)` is present, and the second argument must
     * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
     * during an upgrade.
     */
    string public constant UPGRADE_INTERFACE_VERSION = '5.0.0';

    /**
     * @dev The call is from an unauthorized context.
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev The storage `slot` is unsupported as a UUID.
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        _checkNotDelegated();
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * ////IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data);
    }

    /**
     * @dev Reverts if the execution is not performed via delegatecall or the execution
     * context is not of a proxy with an ERC1967-compliant implementation pointing to self.
     * See {_onlyProxy}.
     */
    function _checkProxy() internal view virtual {
        if (
            address(this) == __self || // Must be called through delegatecall
            ERC1967Utils.getImplementation() != __self // Must be called through an active proxy
        ) {
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Reverts if the execution is performed via delegatecall.
     * See {notDelegated}.
     */
    function _checkNotDelegated() internal view virtual {
        if (address(this) != __self) {
            // Must not be called through delegatecall
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev Performs an implementation upgrade with a security check for UUPS proxies, and additional setup call.
     *
     * As a security check, {proxiableUUID} is invoked in the new implementation, and the return value
     * is expected to be the implementation slot in ERC1967.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data) private {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != ERC1967Utils.IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } catch {
            // The implementation is not UUPS
            revert ERC1967Utils.ERC1967InvalidImplementation(newImplementation);
        }
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.9;

////import "@openzeppelin/contracts/utils/Strings.sol";
////import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
////import {Address} from "@openzeppelin/contracts/utils/Address.sol";
////import "./DecimalUtils.sol";

library SubjectUtils {
    bytes16 private constant LOWER_HEX_DIGITS = '0123456789abcdef';
    bytes16 private constant UPPER_HEX_DIGITS = '0123456789ABCDEF';
    string public constant STRING_MATCHER = '{string}';
    string public constant UINT_MATCHER = '{uint}';
    string public constant INT_MATCHER = '{int}';
    string public constant DECIMALS_MATCHER = '{decimals}';
    string public constant ETH_ADDR_MATCHER = '{ethAddr}';

    function addressToChecksumHexString(address addr) internal pure returns (string memory) {
        string memory lowerCaseAddrWithOx = Strings.toHexString(addr);

        bytes memory lowerCaseAddr = new bytes(40); // Remove 0x added by the OZ lib
        for (uint8 i = 2; i < 42; i++) {
            lowerCaseAddr[i - 2] = bytes(lowerCaseAddrWithOx)[i];
        }

        // Hash of lowercase addr
        uint256 lowerCaseHash = uint256(keccak256(abi.encodePacked(lowerCaseAddr)));

        // Result hex = 42 chars with 0x prefix
        bytes memory result = new bytes(42);
        result[0] = '0';
        result[1] = 'x';

        // Shift 24 bytes (96 bits) to the right; as we only need first 20 bytes of the hash to compare
        lowerCaseHash >>= 24 * 4;

        uint256 intAddr = uint256(uint160(addr));

        for (uint8 i = 41; i > 1; --i) {
            uint8 hashChar = uint8(lowerCaseHash & 0xf); // Get last char of the hex
            uint8 addrChar = uint8(intAddr & 0xf); // Get last char of the address

            if (hashChar >= 8) {
                result[i] = UPPER_HEX_DIGITS[addrChar];
            } else {
                result[i] = LOWER_HEX_DIGITS[addrChar];
            }

            // Remove last char from both hash and addr
            intAddr >>= 4;
            lowerCaseHash >>= 4;
        }

        return string(result);
    }

    /// @notice Convert bytes to hex string without 0x prefix
    /// @param data bytes to convert
    function bytesToHexString(bytes memory data) internal pure returns (string memory) {
        bytes memory hexChars = '0123456789abcdef';
        bytes memory hexString = new bytes(2 * data.length);

        for (uint256 i = 0; i < data.length; i++) {
            uint256 value = uint256(uint8(data[i]));
            hexString[2 * i] = hexChars[value >> 4];
            hexString[2 * i + 1] = hexChars[value & 0xf];
        }

        return string(hexString);
    }

    /// @notice Calculate the expected subject.
    /// @param subjectParams Params to be used in the subject
    /// @param template Template to be used for the subject
    function computeExpectedSubject(
        bytes[] memory subjectParams,
        string[] memory template
    ) internal pure returns (string memory expectedSubject) {
        // Construct an expectedSubject from template and the values of emailAuthMsg.subjectParams.
        uint8 nextParamIndex = 0;
        string memory stringParam;
        bool isParamExist;
        for (uint8 i = 0; i < template.length; i++) {
            isParamExist = true;
            if (Strings.equal(template[i], STRING_MATCHER)) {
                string memory param = abi.decode(subjectParams[nextParamIndex], (string));
                stringParam = param;
            } else if (Strings.equal(template[i], UINT_MATCHER)) {
                uint256 param = abi.decode(subjectParams[nextParamIndex], (uint256));
                stringParam = Strings.toString(param);
            } else if (Strings.equal(template[i], INT_MATCHER)) {
                int256 param = abi.decode(subjectParams[nextParamIndex], (int256));
                stringParam = Strings.toStringSigned(param);
            } else if (Strings.equal(template[i], DECIMALS_MATCHER)) {
                uint256 param = abi.decode(subjectParams[nextParamIndex], (uint256));
                stringParam = DecimalUtils.uintToDecimalString(param);
            } else if (Strings.equal(template[i], ETH_ADDR_MATCHER)) {
                address param = abi.decode(subjectParams[nextParamIndex], (address));
                stringParam = addressToChecksumHexString(param);
            } else {
                isParamExist = false;
                stringParam = template[i];
            }

            if (i > 0) {
                expectedSubject = string(abi.encodePacked(expectedSubject, ' '));
            }
            expectedSubject = string(abi.encodePacked(expectedSubject, stringParam));
            if (isParamExist) {
                nextParamIndex++;
            }
        }
        return expectedSubject;
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.9;

////import "./Groth16Verifier.sol";

struct EmailProof {
    string domainName; // Domain name of the sender's email
    bytes32 publicKeyHash; // Hash of the DKIM public key used in email/proof
    uint timestamp; // Timestamp of the email
    string maskedSubject; // Masked subject of the email
    bytes32 emailNullifier; // Nullifier of the email to prevent its reuse.
    bytes32 accountSalt; // Create2 salt of the account
    bool isCodeExist; // Check if the account code is exist
    bytes proof; // ZK Proof of Email
}

contract Verifier {
    Groth16Verifier groth16Verifier;

    uint256 public constant DOMAIN_FIELDS = 9;
    uint256 public constant DOMAIN_BYTES = 255;
    uint256 public constant SUBJECT_FIELDS = 20;
    uint256 public constant SUBJECT_BYTES = 605;

    constructor() {
        groth16Verifier = new Groth16Verifier();
    }

    function verifyEmailProof(EmailProof memory proof) public view returns (bool) {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = abi.decode(
            proof.proof,
            (uint256[2], uint256[2][2], uint256[2])
        );

        uint256[DOMAIN_FIELDS + SUBJECT_FIELDS + 5] memory pubSignals;
        uint256[] memory stringFields;
        stringFields = _packBytes2Fields(bytes(proof.domainName), DOMAIN_BYTES);
        for (uint256 i = 0; i < DOMAIN_FIELDS; i++) {
            pubSignals[i] = stringFields[i];
        }
        pubSignals[DOMAIN_FIELDS] = uint256(proof.publicKeyHash);
        pubSignals[DOMAIN_FIELDS + 1] = uint256(proof.emailNullifier);
        pubSignals[DOMAIN_FIELDS + 2] = uint256(proof.timestamp);
        stringFields = _packBytes2Fields(bytes(proof.maskedSubject), SUBJECT_BYTES);
        for (uint256 i = 0; i < SUBJECT_FIELDS; i++) {
            pubSignals[DOMAIN_FIELDS + 3 + i] = stringFields[i];
        }
        pubSignals[DOMAIN_FIELDS + 3 + SUBJECT_FIELDS] = uint256(proof.accountSalt);
        pubSignals[DOMAIN_FIELDS + 3 + SUBJECT_FIELDS + 1] = proof.isCodeExist ? 1 : 0;

        return groth16Verifier.verifyProof(pA, pB, pC, pubSignals);
    }

    function _packBytes2Fields(
        bytes memory _bytes,
        uint256 _paddedSize
    ) public pure returns (uint256[] memory) {
        uint256 remain = _paddedSize % 31;
        uint256 numFields = (_paddedSize - remain) / 31;
        if (remain > 0) {
            numFields += 1;
        }
        uint256[] memory fields = new uint[](numFields);
        uint256 idx = 0;
        uint256 byteVal = 0;
        for (uint256 i = 0; i < numFields; i++) {
            for (uint256 j = 0; j < 31; j++) {
                idx = i * 31 + j;
                if (idx >= _paddedSize) {
                    break;
                }
                if (idx >= _bytes.length) {
                    byteVal = 0;
                } else {
                    byteVal = uint256(uint8(_bytes[idx]));
                }
                if (j == 0) {
                    fields[i] = byteVal;
                } else {
                    fields[i] += (byteVal << (8 * j));
                }
            }
        }
        return fields;
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/Ownable.sol";
////import "./interfaces/IDKIMRegistry.sol";

/**
  A Registry that store the hash(dkim_public_key) for each domain
  The hash is calculated by taking Poseidon of DKIM key split into 9 chunks of 242 bits each

  https://zkrepl.dev/?gist=43ce7dce2466c63812f6efec5b13aa73 can be used to generate the public key hash.
  The same code is used in EmailVerifier.sol
  Input is DKIM pub key split into 17 chunks of 121 bits. You can use `helpers` package to fetch/split DKIM keys
 */
contract DKIMRegistry is IDKIMRegistry, Ownable {
    constructor(address _signer) Ownable(_signer) {}

    event DKIMPublicKeyHashRegistered(string domainName, bytes32 publicKeyHash);
    event DKIMPublicKeyHashRevoked(bytes32 publicKeyHash);

    // Mapping from domain name to DKIM public key hash
    mapping(string => mapping(bytes32 => bool)) public dkimPublicKeyHashes;

    // DKIM public that are revoked (eg: in case of private key compromise)
    mapping(bytes32 => bool) public revokedDKIMPublicKeyHashes;

    function _stringEq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function isDKIMPublicKeyHashValid(
        string memory domainName,
        bytes32 publicKeyHash
    ) public view returns (bool) {
        if (revokedDKIMPublicKeyHashes[publicKeyHash]) {
            return false;
        }

        if (dkimPublicKeyHashes[domainName][publicKeyHash]) {
            return true;
        }

        return false;
    }

    function setDKIMPublicKeyHash(
        string memory domainName,
        bytes32 publicKeyHash
    ) public onlyOwner {
        require(!revokedDKIMPublicKeyHashes[publicKeyHash], 'cannot set revoked pubkey');

        dkimPublicKeyHashes[domainName][publicKeyHash] = true;

        emit DKIMPublicKeyHashRegistered(domainName, publicKeyHash);
    }

    function setDKIMPublicKeyHashes(
        string memory domainName,
        bytes32[] memory publicKeyHashes
    ) public onlyOwner {
        for (uint256 i = 0; i < publicKeyHashes.length; i++) {
            setDKIMPublicKeyHash(domainName, publicKeyHashes[i]);
        }
    }

    function revokeDKIMPublicKeyHash(bytes32 publicKeyHash) public onlyOwner {
        revokedDKIMPublicKeyHashes[publicKeyHash] = true;

        emit DKIMPublicKeyHashRevoked(publicKeyHash);
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.20;

////import {Proxy} from "../Proxy.sol";
////import {ERC1967Utils} from "./ERC1967Utils.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `implementation`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `implementation`. This will typically be an
     * encoded function call, and allows initializing the storage of the proxy like a Solidity constructor.
     *
     * Requirements:
     *
     * - If `data` is empty, `msg.value` must be zero.
     */
    constructor(address implementation, bytes memory _data) payable {
        ERC1967Utils.upgradeToAndCall(implementation, _data);
    }

    /**
     * @dev Returns the current implementation address.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function _implementation() internal view virtual override returns (address) {
        return ERC1967Utils.getImplementation();
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Create2.sol)

pragma solidity ^0.8.20;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Not enough balance for performing a CREATE2 deploy.
     */
    error Create2InsufficientBalance(uint256 balance, uint256 needed);

    /**
     * @dev There's no code to deploy.
     */
    error Create2EmptyBytecode();

    /**
     * @dev The deployment failed.
     */
    error Create2FailedDeployment();

    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        if (address(this).balance < amount) {
            revert Create2InsufficientBalance(address(this).balance, amount);
        }
        if (bytecode.length == 0) {
            revert Create2EmptyBytecode();
        }
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        if (addr == address(0)) {
            revert Create2FailedDeployment();
        }
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.12;

////import {EmailProof} from "./utils/Verifier.sol";
////import {IDKIMRegistry} from "@zk-email/contracts/DKIMRegistry.sol";
////import {Verifier} from "./utils/Verifier.sol";
////import {SubjectUtils} from "./libraries/SubjectUtils.sol";
////import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
////import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
////import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @notice Struct to hold the email authentication/authorization message.
struct EmailAuthMsg {
    /// @notice The ID of the subject template that the email subject should satisfy.
    uint templateId;
    /// @notice The parameters in the email subject, which should be taken according to the specified subject template.
    bytes[] subjectParams;
    /// @notice The number of skiiped bytes in the email subject.
    uint skipedSubjectPrefix;
    /// @notice The email proof containing the zk proof and other necessary information for the email verification by the verifier contract.
    EmailProof proof;
}

/// @title Email Authentication/Authorization Contract
/// @notice This contract provides functionalities for the authentication of the email sender and the authentication of the message in the email subject using DKIM and custom verification logic.
/// @dev Inherits from OwnableUpgradeable and UUPSUpgradeable for upgradeability and ownership management.
contract EmailAuth is OwnableUpgradeable, UUPSUpgradeable {
    bytes32 public accountSalt;
    IDKIMRegistry internal dkim;
    Verifier internal verifier;
    address public controller;
    mapping(uint => string[]) public subjectTemplates;
    uint public lastTimestamp;
    mapping(bytes32 => bool) public usedNullifiers;
    bool public timestampCheckEnabled;

    event DKIMRegistryUpdated(address indexed dkimRegistry);
    event VerifierUpdated(address indexed verifier);
    event SubjectTemplateInserted(uint indexed templateId);
    event SubjectTemplateUpdated(uint indexed templateId);
    event SubjectTemplateDeleted(uint indexed templateId);
    event EmailAuthed(
        bytes32 indexed emailNullifier,
        bytes32 indexed accountSalt,
        bool isCodeExist,
        uint templateId
    );
    event TimestampCheckEnabled(bool enabled);

    modifier onlyController() {
        require(msg.sender == controller, 'only controller');
        _;
    }

    constructor() {}

    /// @notice Initialize the contract with an initial owner and an account salt.
    /// @param _initialOwner The address of the initial owner.
    /// @param _accountSalt The account salt to derive CREATE2 address of this contract.
    /// @param _controller The address of the controller contract.
    function initialize(
        address _initialOwner,
        bytes32 _accountSalt,
        address _controller
    ) public initializer {
        __Ownable_init(_initialOwner);
        accountSalt = _accountSalt;
        timestampCheckEnabled = true;
        controller = _controller;
    }

    /// @notice Returns the address of the DKIM registry contract.
    /// @return address The address of the DKIM registry contract.
    function dkimRegistryAddr() public view returns (address) {
        return address(dkim);
    }

    /// @notice Returns the address of the verifier contract.
    /// @return address The Address of the verifier contract.
    function verifierAddr() public view returns (address) {
        return address(verifier);
    }

    /// @notice Initializes the address of the DKIM registry contract.
    /// @param _dkimRegistryAddr The address of the DKIM registry contract.
    function initDKIMRegistry(address _dkimRegistryAddr) public onlyController {
        require(_dkimRegistryAddr != address(0), 'invalid dkim registry address');
        require(address(dkim) == address(0), 'dkim registry already initialized');
        dkim = IDKIMRegistry(_dkimRegistryAddr);
        emit DKIMRegistryUpdated(_dkimRegistryAddr);
    }

    /// @notice Initializes the address of the verifier contract.
    /// @param _verifierAddr The address of the verifier contract.
    function initVerifier(address _verifierAddr) public onlyController {
        require(_verifierAddr != address(0), 'invalid verifier address');
        require(address(verifier) == address(0), 'verifier already initialized');
        verifier = Verifier(_verifierAddr);
        emit VerifierUpdated(_verifierAddr);
    }

    /// @notice Updates the address of the DKIM registry contract.
    /// @param _dkimRegistryAddr The new address of the DKIM registry contract.
    function updateDKIMRegistry(address _dkimRegistryAddr) public onlyOwner {
        require(_dkimRegistryAddr != address(0), 'invalid dkim registry address');
        dkim = IDKIMRegistry(_dkimRegistryAddr);
        emit DKIMRegistryUpdated(_dkimRegistryAddr);
    }

    /// @notice Updates the address of the verifier contract.
    /// @param _verifierAddr The new address of the verifier contract.
    function updateVerifier(address _verifierAddr) public onlyOwner {
        require(_verifierAddr != address(0), 'invalid verifier address');
        verifier = Verifier(_verifierAddr);
        emit VerifierUpdated(_verifierAddr);
    }

    /// @notice Retrieves a subject template by its ID.
    /// @param _templateId The ID of the subject template to be retrieved.
    /// @return string[] The subject template as an array of strings.
    function getSubjectTemplate(uint _templateId) public view returns (string[] memory) {
        require(subjectTemplates[_templateId].length > 0, 'template id not exists');
        return subjectTemplates[_templateId];
    }

    /// @notice Inserts a new subject template.
    /// @dev This function can only be called by the owner of the contract.
    /// @param _templateId The ID for the new subject template.
    /// @param _subjectTemplate The subject template as an array of strings.
    function insertSubjectTemplate(
        uint _templateId,
        string[] memory _subjectTemplate
    ) public onlyController {
        require(_subjectTemplate.length > 0, 'subject template is empty');
        require(subjectTemplates[_templateId].length == 0, 'template id already exists');
        subjectTemplates[_templateId] = _subjectTemplate;
        emit SubjectTemplateInserted(_templateId);
    }

    /// @notice Updates an existing subject template by its ID.
    /// @dev This function can only be called by the controller contract.
    /// @param _templateId The ID of the template to update.
    /// @param _subjectTemplate The new subject template as an array of strings.
    function updateSubjectTemplate(
        uint _templateId,
        string[] memory _subjectTemplate
    ) public onlyController {
        require(_subjectTemplate.length > 0, 'subject template is empty');
        require(subjectTemplates[_templateId].length > 0, 'template id not exists');
        subjectTemplates[_templateId] = _subjectTemplate;
        emit SubjectTemplateUpdated(_templateId);
    }

    /// @notice Deletes an existing subject template by its ID.
    /// @dev This function can only be called by the owner of the contract.
    /// @param _templateId The ID of the subject template to be deleted.
    function deleteSubjectTemplate(uint _templateId) public onlyController {
        require(subjectTemplates[_templateId].length > 0, 'template id not exists');
        delete subjectTemplates[_templateId];
        emit SubjectTemplateDeleted(_templateId);
    }

    /// @notice Authenticate the email sender and authorize the message in the email subject based on the provided email auth message.
    /// @dev This function can only be called by the controller contract.
    /// @param emailAuthMsg The email auth message containing all necessary information for authentication and authorization.
    function authEmail(EmailAuthMsg memory emailAuthMsg) public onlyController {
        string[] memory template = subjectTemplates[emailAuthMsg.templateId];
        require(template.length > 0, 'template id not exists');
        require(
            dkim.isDKIMPublicKeyHashValid(
                emailAuthMsg.proof.domainName,
                emailAuthMsg.proof.publicKeyHash
            ) == true,
            'invalid dkim public key hash'
        );
        require(
            usedNullifiers[emailAuthMsg.proof.emailNullifier] == false,
            'email nullifier already used'
        );
        require(accountSalt == emailAuthMsg.proof.accountSalt, 'invalid account salt');
        require(
            timestampCheckEnabled == false ||
                emailAuthMsg.proof.timestamp == 0 ||
                emailAuthMsg.proof.timestamp > lastTimestamp,
            'invalid timestamp'
        );

        // Construct an expectedSubject from template and the values of emailAuthMsg.subjectParams.
        string memory expectedSubject = SubjectUtils.computeExpectedSubject(
            emailAuthMsg.subjectParams,
            template
        );
        string memory trimmedMaskedSubject = removePrefix(
            emailAuthMsg.proof.maskedSubject,
            emailAuthMsg.skipedSubjectPrefix
        );
        require(Strings.equal(expectedSubject, trimmedMaskedSubject), 'invalid subject');
        require(verifier.verifyEmailProof(emailAuthMsg.proof) == true, 'invalid email proof');

        usedNullifiers[emailAuthMsg.proof.emailNullifier] = true;
        lastTimestamp = emailAuthMsg.proof.timestamp;
        emit EmailAuthed(
            emailAuthMsg.proof.emailNullifier,
            emailAuthMsg.proof.accountSalt,
            emailAuthMsg.proof.isCodeExist,
            emailAuthMsg.templateId
        );
    }

    /// @notice Enables or disables the timestamp check.
    /// @dev This function can only be called by the contract owner.
    /// @param _enabled Boolean flag to enable or disable the timestamp check.
    function setTimestampCheckEnabled(bool _enabled) public onlyController {
        timestampCheckEnabled = _enabled;
        emit TimestampCheckEnabled(_enabled);
    }

    /// @notice Upgrade the implementation of the proxy.
    /// @param newImplementation Address of the new implementation.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function removePrefix(string memory str, uint numChars) private pure returns (string memory) {
        require(numChars <= bytes(str).length, 'Invalid number of characters');

        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(strBytes.length - numChars);

        for (uint i = numChars; i < strBytes.length; i++) {
            result[i - numChars] = strBytes[i];
        }

        return string(result);
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.25;

////import {
//     EnumerableGuardianMap,
//     GuardianStorage,
//     GuardianStatus
// } from "./libraries/EnumerableGuardianMap.sol";
////import { IEmailRecoveryManager } from "./interfaces/IEmailRecoveryManager.sol";
////import { IGuardianManager } from "./interfaces/IGuardianManager.sol";

/**
 * A contract to manage guardians
 */
abstract contract GuardianManager is IGuardianManager {
    using EnumerableGuardianMap for EnumerableGuardianMap.AddressToGuardianMap;

    /**
     * Account to guardian config
     */
    mapping(address account => GuardianManager.GuardianConfig guardianConfig)
        internal guardianConfigs;

    /**
     * Account address to guardian address to guardian storage
     */
    mapping(address account => EnumerableGuardianMap.AddressToGuardianMap guardian)
        internal guardiansStorage;

    /**
     * @notice Modifier to check recovery status. Reverts if recovery is in process for the account
     */
    modifier onlyWhenNotRecovering() {
        if (IEmailRecoveryManager(address(this)).getRecoveryRequest(msg.sender).currentWeight > 0) {
            revert RecoveryInProcess();
        }
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       GUARDIAN LOGIC                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Retrieves the guardian configuration for a given account
     * @param account The address of the account for which the guardian configuration is being
     * retrieved
     * @return GuardianConfig The guardian configuration for the specified account
     */
    function getGuardianConfig(address account) public view returns (GuardianConfig memory) {
        return guardianConfigs[account];
    }

    /**
     * @notice Retrieves the guardian storage details for a given guardian and account
     * @param account The address of the account associated with the guardian
     * @param guardian The address of the guardian
     * @return GuardianStorage The guardian storage details for the specified guardian and account
     */
    function getGuardian(
        address account,
        address guardian
    ) public view returns (GuardianStorage memory) {
        return guardiansStorage[account].get(guardian);
    }

    /**
     * @notice Sets up guardians for a given account with specified weights and threshold
     * @dev This function can only be called once and ensures the guardians, weights, and threshold
     * are correctly configured
     * @param account The address of the account for which guardians are being set up
     * @param guardians An array of guardian addresses
     * @param weights An array of weights corresponding to each guardian
     * @param threshold The threshold weight required for guardians to approve recovery attempts
     */
    function setupGuardians(
        address account,
        address[] memory guardians,
        uint256[] memory weights,
        uint256 threshold
    ) internal returns (uint256, uint256) {
        uint256 guardianCount = guardians.length;

        if (guardianCount != weights.length) {
            revert IncorrectNumberOfWeights(guardianCount, weights.length);
        }

        if (threshold == 0) {
            revert ThresholdCannotBeZero();
        }

        for (uint256 i = 0; i < guardianCount; i++) {
            _addGuardian(account, guardians[i], weights[i]);
        }

        uint256 totalWeight = guardianConfigs[account].totalWeight;
        if (threshold > totalWeight) {
            revert ThresholdExceedsTotalWeight(threshold, totalWeight);
        }

        guardianConfigs[account].threshold = threshold;

        return (guardianCount, totalWeight);
    }

    /**
     * @notice Adds a guardian for the caller's account with a specified weight
     * @dev This function can only be called by the account associated with the guardian and only if
     * no recovery is in process
     * @param guardian The address of the guardian to be added
     * @param weight The weight assigned to the guardian
     */
    function addGuardian(address guardian, uint256 weight) public onlyWhenNotRecovering {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function should be called first
        if (guardianConfigs[msg.sender].threshold == 0) {
            revert SetupNotCalled();
        }

        _addGuardian(msg.sender, guardian, weight);
    }

    /**
     * @notice Internal fucntion to add a guardian for the caller's account with a specified weight
     * @dev A guardian is added, but not accepted after this function has been called
     * @param guardian The address of the guardian to be added
     * @param weight The weight assigned to the guardian
     */
    function _addGuardian(address account, address guardian, uint256 weight) internal {
        if (guardian == address(0) || guardian == account) {
            revert InvalidGuardianAddress(guardian);
        }

        if (weight == 0) {
            revert InvalidGuardianWeight();
        }

        bool success = guardiansStorage[account].set({
            key: guardian,
            value: GuardianStorage(GuardianStatus.REQUESTED, weight)
        });
        if (!success) {
            revert AddressAlreadyGuardian();
        }

        guardianConfigs[account].guardianCount++;
        guardianConfigs[account].totalWeight += weight;

        emit AddedGuardian(account, guardian, weight);
    }

    /**
     * @notice Removes a guardian for the caller's account
     * @dev This function can only be called by the account associated with the guardian and only if
     * no recovery is in process
     * @param guardian The address of the guardian to be removed
     */
    function removeGuardian(address guardian) external onlyWhenNotRecovering {
        GuardianConfig memory guardianConfig = guardianConfigs[msg.sender];
        GuardianStorage memory guardianStorage = guardiansStorage[msg.sender].get(guardian);

        bool success = guardiansStorage[msg.sender].remove(guardian);
        if (!success) {
            // false means that the guardian was not present in the map. This serves as a proxy that
            // the account is not authorized to remove this guardian
            revert AddressNotGuardianForAccount();
        }

        // Only allow guardian removal if threshold can still be reached.
        uint256 newTotalWeight = guardianConfig.totalWeight - guardianStorage.weight;
        if (newTotalWeight < guardianConfig.threshold) {
            revert ThresholdExceedsTotalWeight(newTotalWeight, guardianConfig.threshold);
        }

        guardianConfigs[msg.sender].guardianCount--;
        guardianConfigs[msg.sender].totalWeight -= guardianStorage.weight;
        if (guardianStorage.status == GuardianStatus.ACCEPTED) {
            guardianConfigs[msg.sender].acceptedWeight -= guardianStorage.weight;
        }

        emit RemovedGuardian(msg.sender, guardian, guardianStorage.weight);
    }

    /**
     * @notice Changes the threshold for guardian approvals for the caller's account
     * @dev This function can only be called by the account associated with the guardian config and
     * only if no recovery is in process
     * @param threshold The new threshold for guardian approvals
     */
    function changeThreshold(uint256 threshold) external onlyWhenNotRecovering {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function should be called first
        if (guardianConfigs[msg.sender].threshold == 0) {
            revert SetupNotCalled();
        }

        // Validate that threshold is smaller than the total weight.
        if (threshold > guardianConfigs[msg.sender].totalWeight) {
            revert ThresholdExceedsTotalWeight(threshold, guardianConfigs[msg.sender].totalWeight);
        }

        // Guardian weight should be at least 1
        if (threshold == 0) {
            revert ThresholdCannotBeZero();
        }

        guardianConfigs[msg.sender].threshold = threshold;
        emit ChangedThreshold(msg.sender, threshold);
    }

    /**
     * @notice Updates the status for a guardian
     * @param account The address of the account associated with the guardian
     * @param guardian The address of the guardian
     * @param newStatus The new status for the guardian
     */
    function updateGuardianStatus(
        address account,
        address guardian,
        GuardianStatus newStatus
    ) internal {
        GuardianStorage memory guardianStorage = guardiansStorage[account].get(guardian);
        if (newStatus == guardianStorage.status) {
            revert StatusCannotBeTheSame(newStatus);
        }

        guardiansStorage[account].set({
            key: guardian,
            value: GuardianStorage(newStatus, guardianStorage.weight)
        });
        emit GuardianStatusUpdated(account, guardian, newStatus);
    }

    /**
     * @notice Removes all guardians associated with an account
     * @dev Does not remove guardian config, this should be modified at the same time as calling
     * this function
     * @param account The address of the account associated with the guardians
     */
    function removeAllGuardians(address account) internal {
        guardiansStorage[account].removeAll(guardiansStorage[account].keys());
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.25;

interface IEmailRecoverySubjectHandler {
    function acceptanceSubjectTemplates() external pure returns (string[][] memory);

    function recoverySubjectTemplates() external pure returns (string[][] memory);

    function extractRecoveredAccountFromAcceptanceSubject(
        bytes[] memory subjectParams,
        uint256 templateIdx
    ) external view returns (address);

    function extractRecoveredAccountFromRecoverySubject(
        bytes[] memory subjectParams,
        uint256 templateIdx
    ) external view returns (address);

    function validateAcceptanceSubject(
        uint256 templateIdx,
        bytes[] memory subjectParams
    ) external view returns (address);

    function validateRecoverySubject(
        uint256 templateIdx,
        bytes[] memory subjectParams,
        address expectedRecoveryModule
    ) external view returns (address);

    function parseRecoveryCalldataHash(
        uint256 templateIdx,
        bytes[] memory subjectParams
    ) external view returns (bytes32);
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.12;

////import "./EmailAuth.sol";
////import "@openzeppelin/contracts/utils/Create2.sol";
////import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {L2ContractHelper} from '@matterlabs/zksync-contracts/l2/contracts/L2ContractHelper.sol';
import {DEPLOYER_SYSTEM_CONTRACT, IContractDeployer} from '@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol';
import {SystemContractsCaller} from '@matterlabs/zksync-contracts/l2/system-contracts/libraries/SystemContractsCaller.sol';

/// @title Email Account Recovery Contract
/// @notice Provides mechanisms for email-based account recovery, leveraging guardians and template-based email verification.
/// @dev This contract is abstract and requires implementation of several methods for configuring a new guardian and recovering a wallet.
abstract contract EmailAccountRecovery {
    uint8 constant EMAIL_ACCOUNT_RECOVERY_VERSION_ID = 1;
    address public verifierAddr;
    address public dkimAddr;
    address public emailAuthImplementationAddr;
    bytes32 public proxyBytecodeHash;

    /// @notice Returns the address of the verifier contract.
    /// @dev This function is virtual and can be overridden by inheriting contracts.
    /// @return address The address of the verifier contract.
    function verifier() public view virtual returns (address) {
        return verifierAddr;
    }

    /// @notice Returns the address of the DKIM contract.
    /// @dev This function is virtual and can be overridden by inheriting contracts.
    /// @return address The address of the DKIM contract.
    function dkim() public view virtual returns (address) {
        return dkimAddr;
    }

    /// @notice Returns the address of the email auth contract implementation.
    /// @dev This function is virtual and can be overridden by inheriting contracts.
    /// @return address The address of the email authentication contract implementation.
    function emailAuthImplementation() public view virtual returns (address) {
        return emailAuthImplementationAddr;
    }

    /// @notice Returns a two-dimensional array of strings representing the subject templates for an acceptance by a new guardian's.
    /// @dev This function is virtual and should be implemented by inheriting contracts to define specific acceptance subject templates.
    /// @return string[][] A two-dimensional array of strings, where each inner array represents a set of fixed strings and matchers for a subject template.
    function acceptanceSubjectTemplates() public view virtual returns (string[][] memory);

    /// @notice Returns a two-dimensional array of strings representing the subject templates for email recovery.
    /// @dev This function is virtual and should be implemented by inheriting contracts to define specific recovery subject templates.
    /// @return string[][] A two-dimensional array of strings, where each inner array represents a set of fixed strings and matchers for a subject template.
    function recoverySubjectTemplates() public view virtual returns (string[][] memory);

    /// @notice Extracts the account address to be recovered from the subject parameters of an acceptance email.
    /// @dev This function is virtual and should be implemented by inheriting contracts to extract the account address from the subject parameters.
    /// @param subjectParams The subject parameters of the acceptance email.
    /// @param templateIdx The index of the acceptance subject template.
    function extractRecoveredAccountFromAcceptanceSubject(
        bytes[] memory subjectParams,
        uint templateIdx
    ) public view virtual returns (address);

    /// @notice Extracts the account address to be recovered from the subject parameters of a recovery email.
    /// @dev This function is virtual and should be implemented by inheriting contracts to extract the account address from the subject parameters.
    /// @param subjectParams The subject parameters of the recovery email.
    /// @param templateIdx The index of the recovery subject template.
    function extractRecoveredAccountFromRecoverySubject(
        bytes[] memory subjectParams,
        uint templateIdx
    ) public view virtual returns (address);

    function acceptGuardian(
        address guardian,
        uint templateIdx,
        bytes[] memory subjectParams,
        bytes32 emailNullifier
    ) internal virtual;

    function processRecovery(
        address guardian,
        uint templateIdx,
        bytes[] memory subjectParams,
        bytes32 emailNullifier
    ) internal virtual;

    /// @notice Completes the recovery process.
    /// @dev This function must be implemented by inheriting contracts to finalize the recovery process.
    /// @param account The address of the account to be recovered.
    /// @param completeCalldata The calldata for the recovery process.
    function completeRecovery(address account, bytes memory completeCalldata) external virtual;

    /// @notice Computes the address for email auth contract using the CREATE2 opcode.
    /// @dev This function utilizes the `Create2` library to compute the address. The computation uses a provided account address to be recovered, account salt,
    /// and the hash of the encoded ERC1967Proxy creation code concatenated with the encoded email auth contract implementation
    /// address and the initialization call data. This ensures that the computed address is deterministic and unique per account salt.
    /// @param recoveredAccount The address of the account to be recovered.
    /// @param accountSalt A bytes32 salt value, which is assumed to be unique to a pair of the guardian's email address and the wallet address to be recovered.
    /// @return address The computed address.
    function computeEmailAuthAddress(
        address recoveredAccount,
        bytes32 accountSalt
    ) public view returns (address) {
        // If on zksync, we use L2ContractHelper.computeCreate2Address
        if (block.chainid == 324 || block.chainid == 300) {
            // TODO: The bytecodeHash is hardcoded here because type(ERC1967Proxy).creationCode doesn't work on eraVM currently
            // If you failed some test cases, check the bytecodeHash by yourself
            // see, test/ComputeCreate2Address.t.sol
            return
                L2ContractHelper.computeCreate2Address(
                    address(this),
                    accountSalt,
                    bytes32(0x0100002f564d6017603b63f3adc01ad4c4367e355ef47d34a07a06ea98359c18),
                    keccak256(
                        abi.encode(
                            emailAuthImplementation(),
                            abi.encodeCall(
                                EmailAuth.initialize,
                                (recoveredAccount, accountSalt, address(this))
                            )
                        )
                    )
                );
        } else {
            return
                Create2.computeAddress(
                    accountSalt,
                    keccak256(
                        abi.encodePacked(
                            type(ERC1967Proxy).creationCode,
                            abi.encode(
                                emailAuthImplementation(),
                                abi.encodeCall(
                                    EmailAuth.initialize,
                                    (recoveredAccount, accountSalt, address(this))
                                )
                            )
                        )
                    )
                );
        }
    }

    /// @notice Calculates a unique subject template ID for an acceptance subject template using its index.
    /// @dev Encodes the email account recovery version ID, "ACCEPTANCE", and the template index,
    /// then uses keccak256 to hash these values into a uint ID.
    /// @param templateIdx The index of the acceptance subject template.
    /// @return uint The computed uint ID.
    function computeAcceptanceTemplateId(uint templateIdx) public pure returns (uint) {
        return
            uint256(
                keccak256(abi.encode(EMAIL_ACCOUNT_RECOVERY_VERSION_ID, 'ACCEPTANCE', templateIdx))
            );
    }

    /// @notice Calculates a unique ID for a recovery subject template using its index.
    /// @dev Encodes the email account recovery version ID, "RECOVERY", and the template index,
    /// then uses keccak256 to hash these values into a uint256 ID.
    /// @param templateIdx The index of the recovery subject template.
    /// @return uint The computed uint ID.
    function computeRecoveryTemplateId(uint templateIdx) public pure returns (uint) {
        return
            uint256(
                keccak256(abi.encode(EMAIL_ACCOUNT_RECOVERY_VERSION_ID, 'RECOVERY', templateIdx))
            );
    }

    /// @notice Handles an acceptance by a new guardian.
    /// @dev This function validates the email auth message, deploys a new EmailAuth contract as a proxy if validations pass and initializes the contract.
    /// @param emailAuthMsg The email auth message for the email send from the guardian.
    /// @param templateIdx The index of the subject template for acceptance, which should match with the subject in the given email auth message.
    function handleAcceptance(EmailAuthMsg memory emailAuthMsg, uint templateIdx) external {
        address recoveredAccount = extractRecoveredAccountFromAcceptanceSubject(
            emailAuthMsg.subjectParams,
            templateIdx
        );
        require(recoveredAccount != address(0), 'invalid account in email');
        address guardian = computeEmailAuthAddress(
            recoveredAccount,
            emailAuthMsg.proof.accountSalt
        );
        uint templateId = computeAcceptanceTemplateId(templateIdx);
        require(templateId == emailAuthMsg.templateId, 'invalid template id');
        require(emailAuthMsg.proof.isCodeExist == true, 'isCodeExist is false');

        EmailAuth guardianEmailAuth;
        if (guardian.code.length == 0) {
            if (block.chainid == 324 || block.chainid == 300) {
                (bool success, bytes memory returnData) = SystemContractsCaller
                    .systemCallWithReturndata(
                        uint32(gasleft()),
                        address(DEPLOYER_SYSTEM_CONTRACT),
                        uint128(0),
                        abi.encodeCall(
                            DEPLOYER_SYSTEM_CONTRACT.create2,
                            (
                                emailAuthMsg.proof.accountSalt,
                                proxyBytecodeHash,
                                abi.encode(
                                    emailAuthImplementation(),
                                    abi.encodeCall(
                                        EmailAuth.initialize,
                                        (
                                            recoveredAccount,
                                            emailAuthMsg.proof.accountSalt,
                                            address(this)
                                        )
                                    )
                                )
                            )
                        )
                    );
                address payable proxyAddress = abi.decode(returnData, (address));
                ERC1967Proxy proxy = ERC1967Proxy(proxyAddress);
                guardianEmailAuth = EmailAuth(address(proxy));
                guardianEmailAuth.initialize(
                    recoveredAccount,
                    emailAuthMsg.proof.accountSalt,
                    address(this)
                );
            } else {
                // Deploy proxy of the guardian's EmailAuth contract
                ERC1967Proxy proxy = new ERC1967Proxy{salt: emailAuthMsg.proof.accountSalt}(
                    emailAuthImplementation(),
                    abi.encodeCall(
                        EmailAuth.initialize,
                        (recoveredAccount, emailAuthMsg.proof.accountSalt, address(this))
                    )
                );
                guardianEmailAuth = EmailAuth(address(proxy));
            }
            guardianEmailAuth.initDKIMRegistry(dkim());
            guardianEmailAuth.initVerifier(verifier());
            for (uint idx = 0; idx < acceptanceSubjectTemplates().length; idx++) {
                guardianEmailAuth.insertSubjectTemplate(
                    computeAcceptanceTemplateId(idx),
                    acceptanceSubjectTemplates()[idx]
                );
            }
            for (uint idx = 0; idx < recoverySubjectTemplates().length; idx++) {
                guardianEmailAuth.insertSubjectTemplate(
                    computeRecoveryTemplateId(idx),
                    recoverySubjectTemplates()[idx]
                );
            }
        } else {
            guardianEmailAuth = EmailAuth(payable(address(guardian)));
            require(guardianEmailAuth.controller() == address(this), 'invalid controller');
        }

        // An assertion to confirm that the authEmail function is executed successfully
        // and does not return an error.
        guardianEmailAuth.authEmail(emailAuthMsg);
        acceptGuardian(
            guardian,
            templateIdx,
            emailAuthMsg.subjectParams,
            emailAuthMsg.proof.emailNullifier
        );
    }

    /// @notice Processes the recovery based on an email from the guardian.
    /// @dev Verify the provided email auth message for a deployed guardian's EmailAuth contract and a specific subject template for recovery.
    /// Requires that the guardian is already deployed, and the template ID corresponds to the `templateId` in the given email auth message. Once validated.
    /// @param emailAuthMsg The email auth message for recovery.
    /// @param templateIdx The index of the subject template for recovery, which should match with the subject in the given email auth message.
    function handleRecovery(EmailAuthMsg memory emailAuthMsg, uint templateIdx) external {
        address recoveredAccount = extractRecoveredAccountFromRecoverySubject(
            emailAuthMsg.subjectParams,
            templateIdx
        );
        require(recoveredAccount != address(0), 'invalid account in email');
        address guardian = computeEmailAuthAddress(
            recoveredAccount,
            emailAuthMsg.proof.accountSalt
        );
        // Check if the guardian is deployed
        require(address(guardian).code.length > 0, 'guardian is not deployed');
        uint templateId = uint256(
            keccak256(abi.encode(EMAIL_ACCOUNT_RECOVERY_VERSION_ID, 'RECOVERY', templateIdx))
        );
        require(templateId == emailAuthMsg.templateId, 'invalid template id');

        EmailAuth guardianEmailAuth = EmailAuth(payable(address(guardian)));

        // An assertion to confirm that the authEmail function is executed successfully
        // and does not return an error.
        guardianEmailAuth.authEmail(emailAuthMsg);

        processRecovery(
            guardian,
            templateIdx,
            emailAuthMsg.subjectParams,
            emailAuthMsg.proof.emailNullifier
        );
    }
}

/**
 *  SourceUnit: /Users/tahos81/Desktop/zkemail/email-recovery/src/EmailRecoveryManager.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.25;

////import { EmailAccountRecovery } from
// "ether-email-auth/packages/contracts/src/EmailAccountRecovery.sol";
////import { IEmailRecoveryManager } from "./interfaces/IEmailRecoveryManager.sol";
////import { IEmailRecoverySubjectHandler } from "./interfaces/IEmailRecoverySubjectHandler.sol";
////import { GuardianManager } from "./GuardianManager.sol";
////import { GuardianStorage, GuardianStatus } from "./libraries/EnumerableGuardianMap.sol";

/**
 * @title EmailRecoveryManager
 * @notice Provides a mechanism for account recovery using email guardians
 * @dev The underlying EmailAccountRecovery contract provides some base logic for deploying
 * guardian contracts and handling email verification.
 *
 * This contract defines a default implementation for email-based recovery. It is designed to
 * provide the core logic for email based account recovery that can be used across different account
 * implementations.
 *
 * EmailRecoveryManager relies on a dedicated recovery module to execute a recovery attempt. This
 * (EmailRecoveryManager) contract defines "what a valid recovery attempt is for an account", and
 * the recovery module defines “how that recovery attempt is executed on the account”. A
 * specific email subject handler is also accociated with a recovery manager. A subject handler
 * defines and validates the recovery email subjects. Developers can write their own subject
 * handlers to make specifc subjects for recovering modules
 */
abstract contract EmailRecoveryManager is
    EmailAccountRecovery,
    GuardianManager,
    IEmailRecoveryManager
{
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    CONSTANTS & STORAGE                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Minimum required time window between when a recovery attempt becomes valid and when it
     * becomes invalid
     */
    uint256 public constant MINIMUM_RECOVERY_WINDOW = 2 days;

    /**
     * The subject handler that returns and validates the subject templates
     */
    address public immutable subjectHandler;

    /**
     * Account address to recovery config
     */
    mapping(address account => RecoveryConfig recoveryConfig) internal recoveryConfigs;

    /**
     * Account address to recovery request
     */
    mapping(address account => RecoveryRequest recoveryRequest) internal recoveryRequests;

    constructor(
        address _verifier,
        address _dkimRegistry,
        address _emailAuthImpl,
        address _subjectHandler
    ) {
        if (_verifier == address(0)) {
            revert InvalidVerifier();
        }
        if (_dkimRegistry == address(0)) {
            revert InvalidDkimRegistry();
        }
        if (_emailAuthImpl == address(0)) {
            revert InvalidEmailAuthImpl();
        }
        if (_subjectHandler == address(0)) {
            revert InvalidSubjectHandler();
        }
        verifierAddr = _verifier;
        dkimAddr = _dkimRegistry;
        emailAuthImplementationAddr = _emailAuthImpl;
        subjectHandler = _subjectHandler;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*       RECOVERY CONFIG, REQUEST AND TEMPLATE GETTERS        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Retrieves the recovery configuration for a given account
     * @param account The address of the account for which the recovery configuration is being
     * retrieved
     * @return RecoveryConfig The recovery configuration for the specified account
     */
    function getRecoveryConfig(address account) external view returns (RecoveryConfig memory) {
        return recoveryConfigs[account];
    }

    /**
     * @notice Retrieves the recovery request details for a given account
     * @param account The address of the account for which the recovery request details are being
     * retrieved
     * @return RecoveryRequest The recovery request details for the specified account
     */
    function getRecoveryRequest(address account) external view returns (RecoveryRequest memory) {
        return recoveryRequests[account];
    }

    /**
     * @notice Returns a two-dimensional array of strings representing the subject templates for an
     * acceptance by a new guardian.
     * @dev This is retrieved from the associated subject handler. Developers can write their own
     * subject handlers, this is useful for account implementations which require different data in
     * the subject or if the email should be in a language that is not English.
     * @return string[][] A two-dimensional array of strings, where each inner array represents a
     * set of fixed strings and matchers for a subject template.
     */
    function acceptanceSubjectTemplates() public view override returns (string[][] memory) {
        return IEmailRecoverySubjectHandler(subjectHandler).acceptanceSubjectTemplates();
    }

    /**
     * @notice Returns a two-dimensional array of strings representing the subject templates for
     * email recovery.
     * @dev This is retrieved from the associated subject handler. Developers can write their own
     * subject handlers, this is useful for account implementations which require different data in
     * the subject or if the email should be in a language that is not English.
     * @return string[][] A two-dimensional array of strings, where each inner array represents a
     * set of fixed strings and matchers for a subject template.
     */
    function recoverySubjectTemplates() public view override returns (string[][] memory) {
        return IEmailRecoverySubjectHandler(subjectHandler).recoverySubjectTemplates();
    }

    /**
     * @notice Extracts the account address to be recovered from the subject parameters of an
     * acceptance email.
     * @dev This is retrieved from the associated subject handler.
     * @param subjectParams The subject parameters of the acceptance email.
     * @param templateIdx The index of the acceptance subject template.
     */
    function extractRecoveredAccountFromAcceptanceSubject(
        bytes[] memory subjectParams,
        uint256 templateIdx
    ) public view override returns (address) {
        return
            IEmailRecoverySubjectHandler(subjectHandler)
                .extractRecoveredAccountFromAcceptanceSubject(subjectParams, templateIdx);
    }

    /**
     * @notice Extracts the account address to be recovered from the subject parameters of a
     * recovery email.
     * @dev This is retrieved from the associated subject handler.
     * @param subjectParams The subject parameters of the recovery email.
     * @param templateIdx The index of the recovery subject template.
     */
    function extractRecoveredAccountFromRecoverySubject(
        bytes[] memory subjectParams,
        uint256 templateIdx
    ) public view override returns (address) {
        return
            IEmailRecoverySubjectHandler(subjectHandler).extractRecoveredAccountFromRecoverySubject(
                subjectParams,
                templateIdx
            );
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     CONFIGURE RECOVERY                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Configures recovery for the caller's account. This is the first core function
     * that must be called during the end-to-end recovery flow
     * @dev Can only be called once for configuration. Sets up the guardians, and validates config
     * parameters, ensuring that no recovery is in process. It is possible to configure guardians at
     * a later stage if neccessary
     * @param guardians An array of guardian addresses
     * @param weights An array of weights corresponding to each guardian
     * @param threshold The threshold weight required for recovery
     * @param delay The delay period before recovery can be executed
     * @param expiry The expiry time after which the recovery attempt is invalid
     */
    function configureRecovery(
        address[] memory guardians,
        uint256[] memory weights,
        uint256 threshold,
        uint256 delay,
        uint256 expiry
    ) internal {
        address account = msg.sender;

        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        if (guardianConfigs[account].threshold > 0) {
            revert SetupAlreadyCalled();
        }

        (uint256 guardianCount, uint256 totalWeight) = setupGuardians(
            account,
            guardians,
            weights,
            threshold
        );

        RecoveryConfig memory recoveryConfig = RecoveryConfig(delay, expiry);
        updateRecoveryConfig(recoveryConfig);

        emit RecoveryConfigured(account, guardianCount, totalWeight, threshold);
    }

    /**
     * @notice Updates and validates the recovery configuration for the caller's account
     * @dev Validates and sets the new recovery configuration for the caller's account, ensuring
     * that no recovery is in process.
     * @param recoveryConfig The new recovery configuration to be set for the caller's account
     */
    function updateRecoveryConfig(
        RecoveryConfig memory recoveryConfig
    ) public onlyWhenNotRecovering {
        address account = msg.sender;

        if (guardianConfigs[account].threshold == 0) {
            revert AccountNotConfigured();
        }
        if (recoveryConfig.delay > recoveryConfig.expiry) {
            revert DelayMoreThanExpiry(recoveryConfig.delay, recoveryConfig.expiry);
        }
        uint256 recoveryWindow = recoveryConfig.expiry - recoveryConfig.delay;
        if (recoveryWindow < MINIMUM_RECOVERY_WINDOW) {
            revert RecoveryWindowTooShort(recoveryWindow);
        }

        recoveryConfigs[account] = recoveryConfig;

        emit RecoveryConfigUpdated(account, recoveryConfig.delay, recoveryConfig.expiry);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HANDLE ACCEPTANCE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Accepts a guardian for the specified account. This is the second core function
     * that must be called during the end-to-end recovery flow
     * @dev Called once per guardian added. Although this adds an extra step to recovery, this
     * acceptance flow is an ////important security feature to ensure that no typos are made when adding
     * a guardian, and that the guardian is in control of the specified email address. Called as
     * part of handleAcceptance in EmailAccountRecovery
     * @param guardian The address of the guardian to be accepted
     * @param templateIdx The index of the template used for acceptance
     * @param subjectParams An array of bytes containing the subject parameters
     * @param {nullifier} Unused parameter. The nullifier acts as a unique identifier for an email,
     * but it is not required in this implementation
     */
    function acceptGuardian(
        address guardian,
        uint256 templateIdx,
        bytes[] memory subjectParams,
        bytes32 /* nullifier */
    ) internal override {
        address account = IEmailRecoverySubjectHandler(subjectHandler).validateAcceptanceSubject(
            templateIdx,
            subjectParams
        );

        if (recoveryRequests[account].currentWeight > 0) {
            revert RecoveryInProcess();
        }

        // This check ensures GuardianStatus is correct and also implicitly that the
        // account in email is a valid account
        GuardianStorage memory guardianStorage = getGuardian(account, guardian);
        if (guardianStorage.status != GuardianStatus.REQUESTED) {
            revert InvalidGuardianStatus(guardianStorage.status, GuardianStatus.REQUESTED);
        }

        updateGuardianStatus(account, guardian, GuardianStatus.ACCEPTED);
        guardianConfigs[account].acceptedWeight += guardianStorage.weight;

        emit GuardianAccepted(account, guardian);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      HANDLE RECOVERY                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Processes a recovery request for a given account. This is the third core function
     * that must be called during the end-to-end recovery flow
     * @dev Called once per guardian until the threshold is reached
     * @param guardian The address of the guardian initiating the recovery
     * @param templateIdx The index of the template used for the recovery request
     * @param subjectParams An array of bytes containing the subject parameters
     * @param {nullifier} Unused parameter. The nullifier acts as a unique identifier for an email,
     * but it is not required in this implementation
     */
    function processRecovery(
        address guardian,
        uint256 templateIdx,
        bytes[] memory subjectParams,
        bytes32 /* nullifier */
    ) internal override {
        address account = IEmailRecoverySubjectHandler(subjectHandler).validateRecoverySubject(
            templateIdx,
            subjectParams,
            address(this)
        );

        GuardianConfig memory guardianConfig = guardianConfigs[account];
        if (guardianConfig.threshold > guardianConfig.acceptedWeight) {
            revert ThresholdExceedsAcceptedWeight(
                guardianConfig.threshold,
                guardianConfig.acceptedWeight
            );
        }

        // This check ensures GuardianStatus is correct and also implicitly that the
        // account in email is a valid account
        GuardianStorage memory guardianStorage = getGuardian(account, guardian);
        if (guardianStorage.status != GuardianStatus.ACCEPTED) {
            revert InvalidGuardianStatus(guardianStorage.status, GuardianStatus.ACCEPTED);
        }

        RecoveryRequest storage recoveryRequest = recoveryRequests[account];

        recoveryRequest.currentWeight += guardianStorage.weight;

        if (recoveryRequest.currentWeight >= guardianConfig.threshold) {
            bytes32 calldataHash = IEmailRecoverySubjectHandler(subjectHandler)
                .parseRecoveryCalldataHash(templateIdx, subjectParams);

            uint256 executeAfter = block.timestamp + recoveryConfigs[account].delay;
            uint256 executeBefore = block.timestamp + recoveryConfigs[account].expiry;

            recoveryRequest.executeAfter = executeAfter;
            recoveryRequest.executeBefore = executeBefore;
            recoveryRequest.calldataHash = calldataHash;

            emit RecoveryProcessed(account, guardian, executeAfter, executeBefore, calldataHash);
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     COMPLETE RECOVERY                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Completes the recovery process for a given account. This is the forth and final
     * core function that must be called during the end-to-end recovery flow. Can be called by
     * anyone.
     * @dev Validates the recovery request by checking the total weight, that the delay has passed,
     * and the request has not expired. Triggers the recovery module to perform the recovery. The
     * recovery module trusts that this contract has validated the recovery attempt. This function
     * deletes the recovery request but recovery config state is maintained so future recovery
     * requests can be made without having to reconfigure everything
     * @param account The address of the account for which the recovery is being completed
     * @param recoveryCalldata The calldata that is passed to recover the validator
     */
    function completeRecovery(address account, bytes calldata recoveryCalldata) external override {
        if (account == address(0)) {
            revert InvalidAccountAddress();
        }
        RecoveryRequest memory recoveryRequest = recoveryRequests[account];

        uint256 threshold = guardianConfigs[account].threshold;
        if (threshold == 0) {
            revert NoRecoveryConfigured();
        }

        if (recoveryRequest.currentWeight < threshold) {
            revert NotEnoughApprovals(recoveryRequest.currentWeight, threshold);
        }

        if (block.timestamp < recoveryRequest.executeAfter) {
            revert DelayNotPassed(block.timestamp, recoveryRequest.executeAfter);
        }

        if (block.timestamp >= recoveryRequest.executeBefore) {
            revert RecoveryRequestExpired(block.timestamp, recoveryRequest.executeBefore);
        }

        bytes32 calldataHash = keccak256(recoveryCalldata);
        if (calldataHash != recoveryRequest.calldataHash) {
            revert InvalidCalldataHash(calldataHash, recoveryRequest.calldataHash);
        }

        delete recoveryRequests[account];

        recover(account, recoveryCalldata);

        emit RecoveryCompleted(account);
    }

    function recover(address account, bytes calldata recoveryCalldata) internal virtual;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    CANCEL/DE-INIT LOGIC                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Cancels the recovery request for the caller's account
     * @dev Deletes the current recovery request associated with the caller's account
     */
    function cancelRecovery() external {
        if (recoveryRequests[msg.sender].currentWeight == 0) {
            revert NoRecoveryInProcess();
        }
        delete recoveryRequests[msg.sender];
        emit RecoveryCancelled(msg.sender);
    }

    /**
     * @notice Removes all state related to an account. Must be called from a configured recovery
     * module
     * @dev In order to prevent unexpected behaviour when reinstalling account modules, the module
     * should be deinitialized. This should include remove state accociated with an account.
     */
    function deInitRecoveryModule() internal onlyWhenNotRecovering {
        delete recoveryConfigs[msg.sender];
        delete recoveryRequests[msg.sender];

        removeAllGuardians(msg.sender);
        delete guardianConfigs[msg.sender];

        emit RecoveryDeInitialized(msg.sender);
    }
}
