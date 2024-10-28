// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {INovaroClient} from "./interfaces/INovaroClient.sol";
import {NovaroErrors} from "./libraries/NovaroErrors.sol";
import {NovaroDataTypes} from "./libraries/NovaroDataTypes.sol";
import {NovaroEvents} from "./libraries/NovaroEvents.sol";
import {IDynamicSocialToken} from "./interfaces/IDynamicSocialToken.sol";
import {FollowerPassToken} from "./tokens/FollowerPassToken.sol";
import {IERC6551Registry} from "./interfaces/IERC6551Registry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NovaroClient is INovaroClient , Ownable(msg.sender){

    string public constant NAME =  "NovaroClient";

    address[] private tokens;

    mapping(address => NovaroDataTypes.FollowerPassTokenData) private tokenDataMapping;

    mapping(address => string)  private systemIdentifiers;

    mapping(address => address) private tokenBoundAccounts;

    address private pool;

    IDynamicSocialToken private dst;

    IERC6551Registry private registry;

    constructor(address _pool) {
        pool = _pool;
    }

    function setAddresses(address _dst, address _registry) onlyOwner external {
        dst = IDynamicSocialToken(_dst);
        registry = IERC6551Registry(_registry);
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
        address account = registry.createAccount(
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt,
            initData
        );
        tokenBoundAccounts[account] = tokenContract;
        emit NovaroEvents.CreateAccount(msg.sender, account);
        return account;
    }


    function createFollowerPassToken(
        string calldata _name,
        string calldata _symbol,
        string calldata _imageUrl,
        string calldata _des
    ) external override {
        address _boundAccount = tokenBoundAccounts[msg.sender];
        if (_boundAccount != address(0) ) {
            revert NovaroErrors.EmptyTokenBoundAccount();
        }
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

    function sell(address _token, uint256 _amount) external {
        if (address(_token) == address(0)) {
            revert NovaroErrors.InvalidAddress();
        }
        FollowerPassToken followerPassToken = FollowerPassToken(_token);
        followerPassToken.transfer(pool, _amount);
        emit NovaroEvents.SellFollowerPassToken(msg.sender, _token, _amount);
    }

    function buy(address _token, uint256 _amount) external {
        if (address (_token) == address(0)) {
            revert NovaroErrors.InvalidAddress();
        }
        FollowerPassToken followerPassToken = FollowerPassToken(_token);
        followerPassToken.approve(msg.sender, _amount);
        followerPassToken.transferFrom(pool, msg.sender, _amount);
        emit NovaroEvents.BuyFollowerPassToken(msg.sender, _token, _amount);
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
