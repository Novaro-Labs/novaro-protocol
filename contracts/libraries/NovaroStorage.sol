// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../account/ERC6551Registry.sol";
import "../tokens/DynamicSocialToken.sol";
import "./NovaroDataTypes.sol";
import "../interfaces/ISocialOracle.sol";

library NovaroStorage {

    bytes32 internal constant CLIENT_STORAGE_SLOT = keccak256('novaro.client.storage');

    struct ClientStorage {
        address[] tokens;
        //onchain data for follower pass tokens
        mapping(address => NovaroDataTypes.FollowerPassTokenData) tokenDataMapping;
        //system identifiers for each account
        mapping(address => string)  systemIdentifiers;
        //erc6551 account bound to each address
        mapping(address => address) tokenBoundAccounts;
        //Last time the user called the off-chain feed function
        mapping(address => uint256)  lastCallTime;
        address pool;
        DynamicSocialToken dst;
        ERC6551Registry  registry;
        ISocialOracle socialOracle;
    }

    function _getClientStorage() public pure returns (ClientStorage storage clientStorage) {
        bytes32 position = CLIENT_STORAGE_SLOT;
        assembly {
            clientStorage.slot := position
        }
    }
}
