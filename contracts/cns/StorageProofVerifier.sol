// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { SparseMerkleTree, TreeEntry } from "./SparseMerkleTree.sol";

/// @notice Interface for the zkSync's contract
interface IZkSyncDiamond {
    /// @notice Returns the hash of the stored batch
    function storedBatchHash(uint256) external view returns (bytes32);
}

/// `StoredBatchInfo` struct declared in https://github.com/matter-labs/era-contracts/blob/main/l1-contracts/contracts/zksync/interfaces/IExecutor.sol
/// @notice Rollup batch stored data
/// @param batchNumber Rollup batch number
/// @param indexRepeatedStorageChanges The serial number of the shortcut index that's used as a unique identifier for storage keys that were used twice or more
/// @param numberOfLayer1Txs Number of priority operations to be processed
/// @param priorityOperationsHash Hash of all priority operations from this batch
/// @param l2LogsTreeRoot Root hash of tree that contains L2 -> L1 messages from this batch
/// @param timestamp Rollup batch timestamp, have the same format as Ethereum batch constant
/// @param commitment Verified input for the zkSync circuit
struct StoredBatchInfo {
    uint64 batchNumber;
    bytes32 batchHash;
    uint64 indexRepeatedStorageChanges;
    uint256 numberOfLayer1Txs;
    bytes32 priorityOperationsHash;
    bytes32 l2LogsTreeRoot;
    uint256 timestamp;
    bytes32 commitment;
}

/// @notice Metadata of the batch provided by the offchain resolver
/// @dev batchHash is omitted because it will be calculated from the proof
struct BatchMetadata {
    uint64 batchNumber;
    uint64 indexRepeatedStorageChanges;
    uint256 numberOfLayer1Txs;
    bytes32 priorityOperationsHash;
    bytes32 l2LogsTreeRoot;
    uint256 timestamp;
    bytes32 commitment;
}

/// @notice Storage proof that proves a storage key-value pair is included in the batch
struct StorageProof {
    // Metadata of the batch
    BatchMetadata metadata;
    // Account and key-value pair of its storage
    address account;
    uint256 key;
    bytes32 value;
    // Proof path and leaf index
    bytes32[] path;
    uint64 index;
}

contract StorageProofVerifier {
    IZkSyncDiamond immutable public zksyncDiamondAddress;
    SparseMerkleTree public smt;

    constructor(IZkSyncDiamond _zksyncDiamondAddress, SparseMerkleTree _smt) {
        zksyncDiamondAddress = _zksyncDiamondAddress;
        smt = _smt;
    }

    /// @notice Verifies the storage proof
    function verify(StorageProof memory _proof) external view returns (bool valid) {
        // Fold the proof path to get hash of L2 state
        bytes32 l2BatchHash = smt.getRootHash(
            _proof.path, 
            TreeEntry({
                key: _proof.key,
                value: _proof.value,
                leafIndex: _proof.index
            }), 
            _proof.account
        );

        // Build stored batch info and compute its hash
        // batchHash of the StoredBatchInfo is computed from the proof
        StoredBatchInfo memory batch = StoredBatchInfo({
            batchNumber: _proof.metadata.batchNumber,
            batchHash: l2BatchHash,
            indexRepeatedStorageChanges: _proof.metadata.indexRepeatedStorageChanges,
            numberOfLayer1Txs: _proof.metadata.numberOfLayer1Txs,
            priorityOperationsHash: _proof.metadata.priorityOperationsHash,
            l2LogsTreeRoot: _proof.metadata.l2LogsTreeRoot,
            timestamp: _proof.metadata.timestamp,
            commitment: _proof.metadata.commitment
        });
        bytes32 computedL1BatchHash = _hashStoredBatchInfo(batch);
        bytes32 l1BatchHash = zksyncDiamondAddress.storedBatchHash(_proof.metadata.batchNumber);

        valid = computedL1BatchHash == l1BatchHash;
    }

    /// @notice Returns the keccak hash of the ABI-encoded StoredBatchInfo
    function _hashStoredBatchInfo(StoredBatchInfo memory _storedBatchInfo) internal pure returns (bytes32) {
        return keccak256(abi.encode(_storedBatchInfo));
    }
}