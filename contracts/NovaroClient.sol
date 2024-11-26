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
import {NovaroStorage} from "./libraries/NovaroStorage.sol";
import {ISocialOracle} from"./interfaces/ISocialOracle.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "hardhat/console.sol";
import {FollowerPassCommunity} from "./tokens/FollowerPassCommunity.sol";

contract NovaroClient is INovaroClient, Ownable(msg.sender){

    string public constant NAME =  "NovaroClient";

    address private treasury;

    using NovaroStorage for NovaroStorage.ClientStorage;

    NovaroStorage.ClientStorage private _clientStorage;

    constructor(address _pool) {
        _clientStorage.pool = _pool;
        treasury = msg.sender;
    }

    function setDynamicSocialToken(address _dst) onlyOwner external {
        _clientStorage.dst = DynamicSocialToken(_dst);
    }

    function setRegistry(address _registry) onlyOwner external {
        _clientStorage.registry = ERC6551Registry(_registry);
    }

    function setSocialOracle(address _socialOracle) onlyOwner external {
        _clientStorage.socialOracle = ISocialOracle(_socialOracle);
    }

    function offChainFeed() external {
        DynamicSocialToken _dst = _clientStorage.dst;
        if (address (_dst) == address(0)) {
            revert NovaroErrors.InvalidDST();
        }
        mapping(address => uint256) storage lastCallTime = _clientStorage.lastCallTime;
        // only feed DST every 24 hours
        uint256 currentTime = block.timestamp;
        if (currentTime < lastCallTime[msg.sender] + 24 hours) {
            revert NovaroErrors.Within24HourPeriod();
        }
        // update last call time
        lastCallTime[msg.sender] = currentTime;
        ISocialOracle _socialOracle = _clientStorage.socialOracle;
        if (address(_socialOracle) == address(0)) {
            revert NovaroErrors.InvalidSocialOracle();
        }
        uint256 _socialScore = _socialOracle.getSocialScore(msg.sender);
        _dst.offChainFeed(msg.sender,_socialScore);
    }

    function createOrFetchAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        address _tokenBoundAccount = _clientStorage.tokenBoundAccounts[msg.sender];
        if (_tokenBoundAccount!= address(0)) {
            emit NovaroEvents.AccountAlreadyBound(msg.sender, _tokenBoundAccount);
            return _tokenBoundAccount;
        }
        if (address (_clientStorage.registry) == address(0)) {
            revert NovaroErrors.InvalidERC6551Registry();
        }
        if (_clientStorage.dst.ownerOf(tokenId)!= msg.sender) {
            revert NovaroErrors.InvalidTokenOwner();
        }
        address account = _clientStorage.registry.createAccount(
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt,
            initData
        );

        _clientStorage.tokenBoundAccounts[msg.sender] = account;
        emit NovaroEvents.CreateAccount(msg.sender, account);
        return account;
    }


    function createCommunityToken(
        address underlying_asset,
        string calldata share_token_name,
        string calldata share_token_symbol
    ) external returns (address){
        FollowerPassCommunity followerPassCommunity = new FollowerPassCommunity(
            IERC20(underlying_asset),
            share_token_name,
            share_token_symbol,
            treasury,
            _clientStorage.tokenBoundAccounts[msg.sender]
        );
        _clientStorage.communities.push(address(followerPassCommunity));
        emit NovaroEvents.CreateCommunityToken(msg.sender, followerPassCommunity);
        return address(followerPassCommunity);
    }

    //=========getter functions=========

    function getSystemIdentifier(address _owner) external view returns (string memory) {
        return _clientStorage.systemIdentifiers[_owner];
    }

    function getCommunities() external view returns (address[] memory) {
        return _clientStorage.communities;
    }

    function getCommunitiesCount() external view returns (uint256) {
        return _clientStorage.communities.length;
    }

    function getDynamicSocialToken() external view returns (address) {
        return address(_clientStorage.dst);
    }

    function getRegistry() external view returns (address) {
        return address(_clientStorage.registry);
    }

}
