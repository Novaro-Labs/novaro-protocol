// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {INovaroClient} from "./interfaces/INovaroClient.sol";
import {NovaroErrors} from "./libraries/NovaroErrors.sol";
import {NovaroEvents} from "./libraries/NovaroEvents.sol";
import {DynamicSocialToken} from "./tokens/DynamicSocialToken.sol";

contract NovaroClient is INovaroClient {
    mapping(string => uint256) private delegateTokenIds;

    DynamicSocialToken public dst;

    constructor(DynamicSocialToken _dst) {
        dst = _dst;
    }

    //admin mint an DST for user when user delegate their NovaID without bind wallet
    function onDelegateReceived(string calldata novaId) external override {
        if (delegateTokenIds[novaId] != 0) {
            revert NovaroErrors.AlreadyBoundDST();
        }
        uint256 tokenId = dst.mint(address(this), 0);
        delegateTokenIds[novaId] = tokenId;
    }

    function createTokenBoundAccount(
        address owner,
        string calldata novaId
    ) external override {
        if (delegateTokenIds[novaId] == 0) {
            revert NovaroErrors.DSTNotMinted();
        }
        if (delegateTokenIds[novaId] == 1) {
            revert NovaroErrors.AlreadyTransferDST();
        }
        //transfer DST to user
        uint256 tokenID = delegateTokenIds[novaId];
        dst.transferFrom(address(this), owner, tokenID);
        //already transfered, set tokenId to 1
        delegateTokenIds[novaId] = 1;
        emit NovaroEvents.CreateTokenBoundAccount(owner, tokenID, novaId);
    }

    // Implement IERC721Receiver to allow this contract to receive ERC721 tokens
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    //=======getters=======
    function getDelegateTokenId(
        string calldata novaId
    ) external view returns (uint256) {
        return delegateTokenIds[novaId];
    }
}
