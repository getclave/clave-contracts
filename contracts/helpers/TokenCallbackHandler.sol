// Copied from '@account-abstraction/contracts/samples/callback/TokenCallbackHandler.sol'

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {IERC777Recipient} from '@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {IERC1155Receiver} from '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';

/**
 * Token callback handler.
 *   Handles supported tokens' callbacks, allowing account receiving these tokens.
 */
contract TokenCallbackHandler is IERC777Recipient, IERC721Receiver, IERC1155Receiver {
    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure override {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /// @dev functon visibility changed to public to allow overriding
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
