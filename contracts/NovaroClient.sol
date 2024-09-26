// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {INovaroClient} from "./interfaces/INovaroClient.sol";
import {NovaroErrors} from "./libraries/NovaroErrors.sol";
import {NovaroDataTypes} from "./libraries/NovaroDataTypes.sol";
import {NovaroEvents} from "./libraries/NovaroEvents.sol";
import {DynamicSocialToken} from "./tokens/DynamicSocialToken.sol";
import {FollowerPassToken} from "./tokens/FollowerPassToken.sol";

contract NovaroClient is INovaroClient {
    mapping(string => uint256) private delegateTokenIds;
    mapping(address => mapping(address => mapping(string =>NovaroDataTypes.FollowerPassTokenData)))
        private followerPassTokens;

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

    function createFollowerPassToken(
        string calldata _name,
        string calldata _symbol,
        string calldata _imageUrl,
        string calldata _des,
        address _boundAccount
    ) external override {
        FollowerPassToken followerPassToken = new FollowerPassToken(
            _name,
            _symbol,
            _boundAccount
        );
        NovaroDataTypes.FollowerPassTokenData memory tokenData = NovaroDataTypes
            .FollowerPassTokenData({
                deployer: msg.sender,
                boundAccount: _boundAccount,
                name: _name,
                symbol: _symbol,
                imageUrl: _imageUrl,
                des: _des
            });
        followerPassTokens[msg.sender][_boundAccount][_symbol] = tokenData;
        emit NovaroEvents.CreateFollowerPassToken(
            msg.sender,
            _boundAccount,
            _symbol,
            _name,
            _imageUrl,
            _des
        );
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

    function getFollowerPassTokenData(
        address owner,
        address boundAccount,
        string calldata symbol
    ) external view returns (NovaroDataTypes.FollowerPassTokenData memory) {
        return followerPassTokens[owner][boundAccount][symbol];
    }
}
