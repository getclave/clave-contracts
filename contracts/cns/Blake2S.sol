// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// https://github.com/AlexNi245/blake2s-solidity/blob/main/contracts/Blake2S.sol

/**
 * @title Blake2S Hash Function for Solidity
 * @notice This library implements the BLAKE2s cryptographic hash function within Solidity.
 *         BLAKE2s is optimized for 8- to 32-bit platforms and produces digests of any size
 *         between 1 and 32 bytes. For more details, see the BLAKE2 RFC at
 *         https://www.rfc-editor.org/rfc/rfc7693.txt.
 */
library Blake2S {
    uint256 public constant DEFAULT_OUTLEN = 32;
    bytes public constant DEFAULT_EMPTY_KEY = "";

    // Initialization Vector constants as defined in the BLAKE2 RFC
    uint32 private constant IV0 = 0x6A09E667;
    uint32 private constant IV1 = 0xBB67AE85;
    uint32 private constant IV2 = 0x3C6EF372;
    uint32 private constant IV3 = 0xA54FF53A;
    uint32 private constant IV4 = 0x510E527F;
    uint32 private constant IV5 = 0x9B05688C;
    uint32 private constant IV6 = 0x1F83D9AB;
    uint32 private constant IV7 = 0x5BE0CD19;

    /**
     * @dev BLAKE2S context struct containing all necessary fields for the hash computation.
     */
    struct BLAKE2S_ctx {
        uint256[2] b; // Input buffer: 2 elements of 32 bytes each to make up 64 bytes
        uint256[8] h; // Chained state: 8 words of 32 bits each
        uint256 t; // Total number of bytes
        uint256 c; // Counter for buffer, indicates how much is filled
        uint256 outlen; // Digest output size
    }

    /**
     * @dev Computes the BLAKE2s hash of the input and returns the digest.
     * @param input The input data to hash.
     * @return The 32-byte hash digest.
     */
    function toDigest(
        bytes memory input
    ) public view returns (bytes32) {
        BLAKE2S_ctx memory ctx;
        uint256[2] memory DEFAULT_EMPTY_INPUT;
        //Custom Keys or Output Size are not supported yet, primarily because they are not tested. However they can be added in the future
        init(
            ctx,
            DEFAULT_OUTLEN,
            DEFAULT_EMPTY_KEY,
            DEFAULT_EMPTY_INPUT,
            DEFAULT_EMPTY_INPUT
        );
        update(ctx, input);
        return finalize(ctx);
    }

    function toDigest(
        bytes memory input1,
        bytes memory input2
    ) public view returns (bytes32) {
        BLAKE2S_ctx memory ctx;
        uint256[2] memory DEFAULT_EMPTY_INPUT;
        //Custom Keys or Output Size are not supported yet, primarily because they are not tested. However they can be added in the future
        init(
            ctx,
            DEFAULT_OUTLEN,
            DEFAULT_EMPTY_KEY,
            DEFAULT_EMPTY_INPUT,
            DEFAULT_EMPTY_INPUT
        );
        update(ctx, input1);
        update(ctx, input2);
        return finalize(ctx);
    }

    /**
     * @dev Initializes the BLAKE2s context with the given parameters.
     * @param ctx The BLAKE2s context to initialize.
     * @param outlen The desired output length of the hash.
     * @param key The key input for keyed hashing (up to 32 bytes).
     * @param salt The salt input for randomizing the hash (exactly 2 uint32s).
     * @param person The personalization input for personalizing the hash (exactly 2 uint32s).
     */
    function init(
        BLAKE2S_ctx memory ctx,
        uint256 outlen,
        bytes memory key,
        uint256[2] memory salt,
        uint256[2] memory person
    ) internal view {
        if (outlen == 0 || outlen > 32 || outlen % 4 != 0 || key.length > 32) revert("outlen");

        ctx.b[0] = 0;
        ctx.b[1] = 0;
        ctx.t = 0;
        ctx.c = 0;

        // Initialize chained-state to IV
        //I think it's more gas efficient to assign the values directly to the array instead of assigning them one by one
        ctx.h[0] = IV0;
        ctx.h[1] = IV1;
        ctx.h[2] = IV2;
        ctx.h[3] = IV3;
        ctx.h[4] = IV4;
        ctx.h[5] = IV5;
        ctx.h[6] = IV6;
        ctx.h[7] = IV7;

        // Set up parameter block
        ctx.h[0] = ctx.h[0] ^ 0x01010000 ^ (uint32(key.length) << 8) ^ outlen;

        if (salt.length == 2) {
            ctx.h[4] = ctx.h[4] ^ salt[0];
            ctx.h[5] = ctx.h[5] ^ salt[1];
        }

        if (person.length == 2) {
            ctx.h[6] = ctx.h[6] ^ person[0];
            ctx.h[7] = ctx.h[7] ^ person[1];
        }

        ctx.outlen = outlen;
    }

    /**
     * @dev Updates the BLAKE2s context with new input data.
     * @param ctx The BLAKE2s context to update.
     * @param input The input data to be added to the hash computation.
     * - 204320
     * - 
     */
    function update(BLAKE2S_ctx memory ctx, bytes memory input) internal view {
        unchecked {
            uint256 inputLength = uint32(input.length);
            uint256 c = ctx.c;
            for (uint256 i = 0; i < inputLength;) {
                // If buffer is full, update byte counters and compress
                if (c == 64) {
                    // BLAKE2s block size is 64 bytes
                    ctx.t += c; // Increment counter t by the number of bytes in the buffer
                    compress(ctx, false);

                    //clear buffer counter after compressing
                    c = 0;
                }

                uint256 size = min(inputLength - i, 64 - c);
                assembly {
                    // Memcpy
                    pop(staticcall(not(0), 0x4, add(add(input, 32), i), size, add(mload(ctx), c), size))
                }
                c += size;
                i += size;
            }
            ctx.c = c;
        }
    }

    function min(uint256 a, uint256 b) internal view returns(uint256) {
        if(a < b) return a;
        return b;
    }

    /**
     * @dev Compresses the BLAKE2s context's internal state with the input buffer.
     * @param ctx The BLAKE2s context containing the state and input buffer.
     * @param last Indicates if this is the last block to compress, setting the finalization flag.
     *
     * The function performs the BLAKE2s compression function, which mixes both the input buffer
     * and the state (chained value) together using the BLAKE2s mixing function 'G'. It updates
     * the internal state with the result of the compression. If 'last' is true, it also performs
     * the necessary operations to finalize the hash, such as inverting the finalization flag.
     */
    function compress(BLAKE2S_ctx memory ctx, bool last) internal view {
        uint256[16] memory v;

        // Initialize v[0..15]
        assembly {
            // memcpy ctx.h[:8] -> v[:8]
            pop(staticcall(not(0), 0x4, mload(add(ctx, 32)), 256, v, 256))
        }
        // Second half from the IV
        v[8] = IV0;
        v[9] = IV1;
        v[10] = IV2;
        v[11] = IV3;
        v[12] = IV4;
        v[13] = IV5;
        v[14] = IV6;
        v[15] = IV7;

        // Low 64 bits of t
        v[12] = (v[12] ^ uint32(ctx.t & 0xFFFFFFFF)) & 0xFFFFFFFF;
        // High 64 bits of t (BLAKE2s uses only 32 bits for t[1], so this is often zeroed)
        v[13] = (v[13] ^ uint32(ctx.t >> 32)) & 0xFFFFFFFF;

        // Set the last block flag if this is the last block
        if (last) {
            v[14] = (~v[14]) & 0xFFFFFFFF;
        }

        unchecked {
            // Initialize b0 and b1 with the bytes from the input buffer, and swap their endianness
            uint256 b0 = ctx.b[0];
            uint256 b1 = ctx.b[1];

            // Swap endianness on 32bit words
            b0 = ((b0 >> 24) & 0x000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF) | 
                 ((b0 >> 8) & 0x0000FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF00) | 
                 ((b0 << 8) & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) | 
                 ((b0 << 24) & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000);
            b1 = ((b1 >> 24) & 0x000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF) | 
                 ((b1 >> 8) & 0x0000FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF00) | 
                 ((b1 << 8) & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) | 
                 ((b1 << 24) & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000);

            // // SIGMA Block according to rfc7693
            // uint8[16][10] memory SIGMA = [
            //     [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
            //     [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
            //     [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
            //     [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
            //     [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
            //     [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
            //     [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
            //     [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
            //     [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
            //     [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0]
            // ];

            // //call G function 10 times
            // for (uint round = 0; round < 10; round++) {
            //     G(v, 0, 4, 8, 12, m[SIGMA[round][0]], m[SIGMA[round][1]]);
            //     G(v, 1, 5, 9, 13, m[SIGMA[round][2]], m[SIGMA[round][3]]);
            //     G(v, 2, 6, 10, 14, m[SIGMA[round][4]], m[SIGMA[round][5]]);
            //     G(v, 3, 7, 11, 15, m[SIGMA[round][6]], m[SIGMA[round][7]]);
            //     G(v, 0, 5, 10, 15, m[SIGMA[round][8]], m[SIGMA[round][9]]);
            //     G(v, 1, 6, 11, 12, m[SIGMA[round][10]], m[SIGMA[round][11]]);
            //     G(v, 2, 7, 8, 13, m[SIGMA[round][12]], m[SIGMA[round][13]]);
            //     G(v, 3, 4, 9, 14, m[SIGMA[round][14]], m[SIGMA[round][15]]);
            // }
            // Unrolled version of the loop above

            assembly {
                /**
                * @dev Performs the BLAKE2s mixing function 'G' as defined in the BLAKE2 specification.
                * @param v The working vector which is being mixed.
                * @param a Index of the first element in the working vector to mix.
                * @param b Index of the second element in the working vector to mix.
                * @param c Index of the third element in the working vector to mix.
                * @param d Index of the fourth element in the working vector to mix.
                * @param x The first input word to the mixing function.
                * @param y The second input word to the mixing function.
                *
                * This function updates the working vector 'v' with the results of the mixing operations.
                * It is a core part of the compression function, which is in turn a core part of the BLAKE2s hash function.
                */
                function G(z, a, b, c, d, x, y) {
                    // v[a] = (v[a] + v[b] + x) & 0xFFFFFFFF;
                    mstore(add(z, a), and(add(add(mload(add(z, a)), mload(add(z, b))), x), 0xFFFFFFFF))
                    // v[d] = (((v[d] ^ v[a]) >> 16) | ((v[d] ^ v[a]) << 16)) & 0xFFFFFFFF;
                    mstore(add(z, d), and(or(shr(16, xor(mload(add(z, d)), mload(add(z, a)))), shl(16, xor(mload(add(z, d)), mload(add(z, a))))), 0xFFFFFFFF))
                    // v[c] = (v[c] + v[d]) & 0xFFFFFFFF;
                    mstore(add(z, c), and(add(mload(add(z, c)), mload(add(z, d))), 0xFFFFFFFF))
                    // v[b] = (((v[b] ^ v[c]) >> 12) | ((v[b] ^ v[c]) << 20)) & 0xFFFFFFFF;
                    mstore(add(z, b), and(or(shr(12, xor(mload(add(z, b)), mload(add(z, c)))), shl(20, xor(mload(add(z, b)), mload(add(z, c))))), 0xFFFFFFFF))
                    // v[a] = (v[a] + v[b] + y) & 0xFFFFFFFF;
                    mstore(add(z, a), and(add(add(mload(add(z, a)), mload(add(z, b))), y), 0xFFFFFFFF))
                    // v[d] = (((v[d] ^ v[a]) >> 8) | ((v[d] ^ v[a]) << 24)) & 0xFFFFFFFF;
                    mstore(add(z, d), and(or(shr(8, xor(mload(add(z, d)), mload(add(z, a)))), shl(24, xor(mload(add(z, d)), mload(add(z, a))))), 0xFFFFFFFF))
                    // v[c] = (v[c] + v[d]) & 0xFFFFFFFF;
                    mstore(add(z, c), and(add(mload(add(z, c)), mload(add(z, d))), 0xFFFFFFFF))
                    // v[b] = (((v[b] ^ v[c]) >> 7) | ((v[b] ^ v[c]) << 25)) & 0xFFFFFFFF;
                    mstore(add(z, b), and(or(shr(7, xor(mload(add(z, b)), mload(add(z, c)))), shl(25, xor(mload(add(z, b)), mload(add(z, c))))), 0xFFFFFFFF))
                }

                // Round 0
                G(v, 0, 128, 256, 384, and(shr(224, b0), 0xFFFFFFFF), and(shr(192, b0), 0xFFFFFFFF))
                G(v, 32, 160, 288, 416, and(shr(160, b0), 0xFFFFFFFF), and(shr(128, b0), 0xFFFFFFFF))
                G(v, 64, 192, 320, 448, and(shr(96, b0), 0xFFFFFFFF), and(shr(64, b0), 0xFFFFFFFF))
                G(v, 96, 224, 352, 480, and(shr(32, b0), 0xFFFFFFFF), and(shr(0, b0), 0xFFFFFFFF))
                G(v, 0, 160, 320, 480, and(shr(224, b1), 0xFFFFFFFF), and(shr(192, b1), 0xFFFFFFFF))
                G(v, 32, 192, 352, 384, and(shr(160, b1), 0xFFFFFFFF), and(shr(128, b1), 0xFFFFFFFF))
                G(v, 64, 224, 256, 416, and(shr(96, b1), 0xFFFFFFFF), and(shr(64, b1), 0xFFFFFFFF))
                G(v, 96, 128, 288, 448, and(shr(32, b1), 0xFFFFFFFF), and(shr(0, b1), 0xFFFFFFFF))

                // Round 1
                G(v, 0, 128, 256, 384, and(shr(32, b1), 0xFFFFFFFF), and(shr(160, b1), 0xFFFFFFFF))
                G(v, 32, 160, 288, 416, and(shr(96, b0), 0xFFFFFFFF), and(shr(224, b1), 0xFFFFFFFF))
                G(v, 64, 192, 320, 448, and(shr(192, b1), 0xFFFFFFFF), and(shr(0, b1), 0xFFFFFFFF))
                G(v, 96, 224, 352, 480, and(shr(64, b1), 0xFFFFFFFF), and(shr(32, b0), 0xFFFFFFFF))
                G(v, 0, 160, 320, 480, and(shr(192, b0), 0xFFFFFFFF), and(shr(96, b1), 0xFFFFFFFF))
                G(v, 32, 192, 352, 384, and(shr(224, b0), 0xFFFFFFFF), and(shr(160, b0), 0xFFFFFFFF))
                G(v, 64, 224, 256, 416, and(shr(128, b1), 0xFFFFFFFF), and(shr(0, b0), 0xFFFFFFFF))
                G(v, 96, 128, 288, 448, and(shr(64, b0), 0xFFFFFFFF), and(shr(128, b0), 0xFFFFFFFF))

                // Round 2
                G(v, 0, 128, 256, 384, and(shr(128, b1), 0xFFFFFFFF), and(shr(224, b1), 0xFFFFFFFF))
                G(v, 32, 160, 288, 416, and(shr(96, b1), 0xFFFFFFFF), and(shr(224, b0), 0xFFFFFFFF))
                G(v, 64, 192, 320, 448, and(shr(64, b0), 0xFFFFFFFF), and(shr(160, b0), 0xFFFFFFFF))
                G(v, 96, 224, 352, 480, and(shr(0, b1), 0xFFFFFFFF), and(shr(64, b1), 0xFFFFFFFF))
                G(v, 0, 160, 320, 480, and(shr(160, b1), 0xFFFFFFFF), and(shr(32, b1), 0xFFFFFFFF))
                G(v, 32, 192, 352, 384, and(shr(128, b0), 0xFFFFFFFF), and(shr(32, b0), 0xFFFFFFFF))
                G(v, 64, 224, 256, 416, and(shr(0, b0), 0xFFFFFFFF), and(shr(192, b0), 0xFFFFFFFF))
                G(v, 96, 128, 288, 448, and(shr(192, b1), 0xFFFFFFFF), and(shr(96, b0), 0xFFFFFFFF))
                
                // Round 3
                G(v, 0, 128, 256, 384, and(shr(0, b0), 0xFFFFFFFF), and(shr(192, b1), 0xFFFFFFFF))
                G(v, 32, 160, 288, 416, and(shr(128, b0), 0xFFFFFFFF), and(shr(192, b0), 0xFFFFFFFF))
                G(v, 64, 192, 320, 448, and(shr(64, b1), 0xFFFFFFFF), and(shr(96, b1), 0xFFFFFFFF))
                G(v, 96, 224, 352, 480, and(shr(128, b1), 0xFFFFFFFF), and(shr(32, b1), 0xFFFFFFFF))
                G(v, 0, 160, 320, 480, and(shr(160, b0), 0xFFFFFFFF), and(shr(32, b0), 0xFFFFFFFF))
                G(v, 32, 192, 352, 384, and(shr(64, b0), 0xFFFFFFFF), and(shr(160, b1), 0xFFFFFFFF))
                G(v, 64, 224, 256, 416, and(shr(96, b0), 0xFFFFFFFF), and(shr(224, b0), 0xFFFFFFFF))
                G(v, 96, 128, 288, 448, and(shr(0, b1), 0xFFFFFFFF), and(shr(224, b1), 0xFFFFFFFF))

                // Round 4
                G(v, 0, 128, 256, 384, and(shr(192, b1), 0xFFFFFFFF), and(shr(224, b0), 0xFFFFFFFF))
                G(v, 32, 160, 288, 416, and(shr(64, b0), 0xFFFFFFFF), and(shr(0, b0), 0xFFFFFFFF))
                G(v, 64, 192, 320, 448, and(shr(160, b0), 0xFFFFFFFF), and(shr(96, b0), 0xFFFFFFFF))
                G(v, 96, 224, 352, 480, and(shr(160, b1), 0xFFFFFFFF), and(shr(0, b1), 0xFFFFFFFF))
                G(v, 0, 160, 320, 480, and(shr(32, b1), 0xFFFFFFFF), and(shr(192, b0), 0xFFFFFFFF))
                G(v, 32, 192, 352, 384, and(shr(128, b1), 0xFFFFFFFF), and(shr(96, b1), 0xFFFFFFFF))
                G(v, 64, 224, 256, 416, and(shr(32, b0), 0xFFFFFFFF), and(shr(224, b1), 0xFFFFFFFF))
                G(v, 96, 128, 288, 448, and(shr(128, b0), 0xFFFFFFFF), and(shr(64, b1), 0xFFFFFFFF))

                // Round 5
                G(v, 0, 128, 256, 384, and(shr(160, b0), 0xFFFFFFFF), and(shr(96, b1), 0xFFFFFFFF))
                G(v, 32, 160, 288, 416, and(shr(32, b0), 0xFFFFFFFF), and(shr(160, b1), 0xFFFFFFFF))
                G(v, 64, 192, 320, 448, and(shr(224, b0), 0xFFFFFFFF), and(shr(128, b1), 0xFFFFFFFF))
                G(v, 96, 224, 352, 480, and(shr(224, b1), 0xFFFFFFFF), and(shr(128, b0), 0xFFFFFFFF))
                G(v, 0, 160, 320, 480, and(shr(96, b0), 0xFFFFFFFF), and(shr(64, b1), 0xFFFFFFFF))
                G(v, 32, 192, 352, 384, and(shr(0, b0), 0xFFFFFFFF), and(shr(64, b0), 0xFFFFFFFF))
                G(v, 64, 224, 256, 416, and(shr(0, b1), 0xFFFFFFFF), and(shr(32, b1), 0xFFFFFFFF))
                G(v, 96, 128, 288, 448, and(shr(192, b0), 0xFFFFFFFF), and(shr(192, b1), 0xFFFFFFFF))

                // Round 6
                G(v, 0, 128, 256, 384, and(shr(96, b1), 0xFFFFFFFF), and(shr(64, b0), 0xFFFFFFFF))
                G(v, 32, 160, 288, 416, and(shr(192, b0), 0xFFFFFFFF), and(shr(0, b1), 0xFFFFFFFF))
                G(v, 64, 192, 320, 448, and(shr(32, b1), 0xFFFFFFFF), and(shr(64, b1), 0xFFFFFFFF))
                G(v, 96, 224, 352, 480, and(shr(96, b0), 0xFFFFFFFF), and(shr(160, b1), 0xFFFFFFFF))
                G(v, 0, 160, 320, 480, and(shr(224, b0), 0xFFFFFFFF), and(shr(0, b0), 0xFFFFFFFF))
                G(v, 32, 192, 352, 384, and(shr(32, b0), 0xFFFFFFFF), and(shr(128, b0), 0xFFFFFFFF))
                G(v, 64, 224, 256, 416, and(shr(192, b1), 0xFFFFFFFF), and(shr(160, b0), 0xFFFFFFFF))
                G(v, 96, 128, 288, 448, and(shr(224, b1), 0xFFFFFFFF), and(shr(128, b1), 0xFFFFFFFF))

                // Round 7
                G(v, 0, 128, 256, 384, and(shr(64, b1), 0xFFFFFFFF), and(shr(128, b1), 0xFFFFFFFF))
                G(v, 32, 160, 288, 416, and(shr(0, b0), 0xFFFFFFFF), and(shr(32, b1), 0xFFFFFFFF))
                G(v, 64, 192, 320, 448, and(shr(96, b1), 0xFFFFFFFF), and(shr(192, b0), 0xFFFFFFFF))
                G(v, 96, 224, 352, 480, and(shr(128, b0), 0xFFFFFFFF), and(shr(192, b1), 0xFFFFFFFF))
                G(v, 0, 160, 320, 480, and(shr(64, b0), 0xFFFFFFFF), and(shr(224, b0), 0xFFFFFFFF))
                G(v, 32, 192, 352, 384, and(shr(0, b1), 0xFFFFFFFF), and(shr(96, b0), 0xFFFFFFFF))
                G(v, 64, 224, 256, 416, and(shr(224, b1), 0xFFFFFFFF), and(shr(32, b0), 0xFFFFFFFF))
                G(v, 96, 128, 288, 448, and(shr(160, b0), 0xFFFFFFFF), and(shr(160, b1), 0xFFFFFFFF))

                // Round 8
                G(v, 0, 128, 256, 384, and(shr(32, b0), 0xFFFFFFFF), and(shr(0, b1), 0xFFFFFFFF))
                G(v, 32, 160, 288, 416, and(shr(32, b1), 0xFFFFFFFF), and(shr(192, b1), 0xFFFFFFFF))
                G(v, 64, 192, 320, 448, and(shr(128, b1), 0xFFFFFFFF), and(shr(128, b0), 0xFFFFFFFF))
                G(v, 96, 224, 352, 480, and(shr(224, b0), 0xFFFFFFFF), and(shr(224, b1), 0xFFFFFFFF))
                G(v, 0, 160, 320, 480, and(shr(96, b1), 0xFFFFFFFF), and(shr(160, b0), 0xFFFFFFFF))
                G(v, 32, 192, 352, 384, and(shr(64, b1), 0xFFFFFFFF), and(shr(0, b0), 0xFFFFFFFF))
                G(v, 64, 224, 256, 416, and(shr(192, b0), 0xFFFFFFFF), and(shr(96, b0), 0xFFFFFFFF))
                G(v, 96, 128, 288, 448, and(shr(160, b1), 0xFFFFFFFF), and(shr(64, b0), 0xFFFFFFFF))

                // Round 9
                G(v, 0, 128, 256, 384, and(shr(160, b1), 0xFFFFFFFF), and(shr(160, b0), 0xFFFFFFFF))
                G(v, 32, 160, 288, 416, and(shr(224, b1), 0xFFFFFFFF), and(shr(96, b0), 0xFFFFFFFF))
                G(v, 64, 192, 320, 448, and(shr(0, b0), 0xFFFFFFFF), and(shr(32, b0), 0xFFFFFFFF))
                G(v, 96, 224, 352, 480, and(shr(192, b0), 0xFFFFFFFF), and(shr(64, b0), 0xFFFFFFFF))
                G(v, 0, 160, 320, 480, and(shr(0, b1), 0xFFFFFFFF), and(shr(128, b1), 0xFFFFFFFF))
                G(v, 32, 192, 352, 384, and(shr(192, b1), 0xFFFFFFFF), and(shr(32, b1), 0xFFFFFFFF))
                G(v, 64, 224, 256, 416, and(shr(128, b0), 0xFFFFFFFF), and(shr(96, b1), 0xFFFFFFFF))
                G(v, 96, 128, 288, 448, and(shr(64, b1), 0xFFFFFFFF), and(shr(224, b0), 0xFFFFFFFF))
            }
        }


        // Update the state with the result of the G mixing operations
        for (uint i = 0; i < 8; i++) {
            ctx.h[i] = ctx.h[i] ^ v[i] ^ v[i + 8];
        }
    }

    /**
     * @dev Finalizes the hashing process and produces the final hash output.
     * @param ctx The BLAKE2s context that contains the state to be finalized.
     * @param out The array that will receive the final hash output.
     *
     * This function completes the BLAKE2s hash computation by performing the following steps:
     * 1. It adds any remaining unprocessed bytes in the buffer to the total byte count.
     * 2. It calls the compress function one last time with the finalization flag set to true.
     * 3. It converts the internal state from little-endian to big-endian format and stores
     *    the result in the output array.
     * 4. If the desired output length is not a multiple of 4 bytes, it properly pads the final
     *    word in the output array to match the specified output length.
     */
    function finalize(
        BLAKE2S_ctx memory ctx
    ) internal view returns(bytes32 out) {
        unchecked {
            // Add any uncounted bytes
            ctx.t += ctx.c;

            // Compress with finalization flag
            compress(ctx, true);

            // Flip little to big endian and store in output buffer
            for (uint i = 0; i < ctx.outlen / 4; i++) {
                out |= bytes32(uint256(getWords32(ctx.h[i]))) << ((7 - i) * 32);
            }
        }
    }

    /**
     * @dev Converts a 32-bit word from little-endian to big-endian format.
     * @param a The 32-bit word in little-endian format.
     * @return b The 32-bit word in big-endian format.
     */
    function getWords32(uint256 a) private view returns (uint256 b) {
        return
            (a >> 24) |
            ((a >> 8) & 0x0000FF00) |
            ((a << 8) & 0x00FF0000) |
            ((a << 24) & 0xFF000000);
    }
}