// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {INovaroClient} from "./interfaces/INovaroClient.sol";
import {NovaroErrors} from "./libraries/NovaroErrors.sol";
import {NovaroDataTypes} from "./libraries/NovaroDataTypes.sol";
import {NovaroEvents} from "./libraries/NovaroEvents.sol";
import {DynamicSocialToken} from "./tokens/DynamicSocialToken.sol";
import {FollowerPassToken} from "./tokens/FollowerPassToken.sol";

contract NovaroClient is INovaroClient {

    string public constant NAME =  "Novaro Client";

    address[] private tokens;
    mapping(address => NovaroDataTypes.FollowerPassTokenData) private tokenDataMapping;

    DynamicSocialToken private dst;

    constructor(DynamicSocialToken _dst) {
        dst = _dst;
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
                token: address(followerPassToken),
                name: _name,
                symbol: _symbol,
                imageUrl: _imageUrl,
                des: _des
            });
        tokens.push(address(followerPassToken));
        tokenDataMapping[address(followerPassToken)] = tokenData;
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

    function getTokenAddresses() external view returns (address[] memory) {
        return tokens;
    }

    function getAllFollowerPassToken() external view returns (NovaroDataTypes.FollowerPassTokenData[] memory) {
        //cache storage on blockchain to reduce gas usage
        mapping(address => NovaroDataTypes.FollowerPassTokenData) storage _tokenDataMapping = tokenDataMapping;
        address[] memory _tokensAddresses = tokens;
        NovaroDataTypes.FollowerPassTokenData[] memory _tokens = new NovaroDataTypes.FollowerPassTokenData[](_tokensAddresses.length);
        for (uint256 i = 0; i < _tokensAddresses.length; i++) {
            _tokens[i] = _tokenDataMapping[_tokensAddresses[i]];
        }
        return _tokens;
    }
}
