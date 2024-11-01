// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {INovaroClient} from "./interfaces/INovaroClient.sol";
import {NovaroErrors} from "./libraries/NovaroErrors.sol";
import {NovaroDataTypes} from "./libraries/NovaroDataTypes.sol";
import {NovaroEvents} from "./libraries/NovaroEvents.sol";
import {FollowerPassToken} from "./tokens/FollowerPassToken.sol";
import {ERC6551Registry} from "./account/ERC6551Registry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DynamicSocialToken} from "./tokens/DynamicSocialToken.sol";
import "hardhat/console.sol";

contract NovaroClient is INovaroClient , Ownable(msg.sender){

    string public constant NAME =  "NovaroClient";

    address[] private tokens;

    mapping(address => NovaroDataTypes.FollowerPassTokenData) private tokenDataMapping;

    mapping(address => string)  private systemIdentifiers;

    mapping(address => address) private tokenBoundAccounts;

    address private pool;

    DynamicSocialToken private dst;

    ERC6551Registry private registry;

    constructor(address _pool) {
        pool = _pool;
    }

    function setDynamicSocialToken(address _dst) onlyOwner external {
        dst = DynamicSocialToken(_dst);
    }

    function setRegistry(address _registry) onlyOwner external {
        registry = ERC6551Registry(_registry);
    }

    function offChainFeed(uint256 _amount) external {
        if (address (dst) == address(0)) {
            revert NovaroErrors.InvalidDST();
        }
        dst.offChainFeed(msg.sender,_amount);
    }

    function createOrFetchAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        address _tokenBoundAccount = tokenBoundAccounts[msg.sender];
        if (_tokenBoundAccount!= address(0)) {
            emit NovaroEvents.AccountAlreadyBound(msg.sender, _tokenBoundAccount);
            return _tokenBoundAccount;
        }
        if (address (registry) == address(0)) {
            revert NovaroErrors.InvalidERC6551Registry();
        }
        if (dst.ownerOf(tokenId)!= msg.sender) {
            revert NovaroErrors.InvalidTokenOwner();
        }
        address account = registry.createAccount(
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt,
            initData
        );
        tokenBoundAccounts[msg.sender] = account;
        emit NovaroEvents.CreateAccount(msg.sender, account);
        return account;
    }


    function createFollowerPassToken(
        string calldata _name,
        string calldata _symbol,
        string calldata _sourceId,
        string calldata _des
    ) external override {
        address _boundAccount = tokenBoundAccounts[msg.sender];
        if (_boundAccount == address(0) ) {
            revert NovaroErrors.EmptyTokenBoundAccount();
        }
        FollowerPassToken followerPassToken = new FollowerPassToken(
            _name,
            _symbol,
            address (msg.sender)
        );
        NovaroDataTypes.FollowerPassTokenData memory tokenData = NovaroDataTypes
            .FollowerPassTokenData({
                deployer: msg.sender,
                boundAccount: _boundAccount,
                token: address(followerPassToken),
                name: _name,
                symbol: _symbol,
                sourceId: _sourceId,
                des: _des
            });
        tokens.push(address(followerPassToken));
        tokenDataMapping[address(followerPassToken)] = tokenData;
        emit NovaroEvents.CreateFollowerPassToken(
            msg.sender,
            _boundAccount,
            _symbol,
            _name,
            _sourceId,
            _des
        );
    }

    //=========getter functions=========

    function getSystemIdentifier(address _owner) external view returns (string memory) {
        return systemIdentifiers[_owner];
    }

    function getBoundAccount(address _owner) external view returns (address) {
        return tokenBoundAccounts[_owner];
    }

    function getDynamicSocialToken() external view returns (address) {
        return address(dst);
    }

    function getRegistry() external view returns (address) {
        return address(registry);
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
