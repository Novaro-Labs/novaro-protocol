// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library NovaroEvents {
    //DST events
    event OffChainFeed(uint256 indexed tokenId, uint256 indexed exp);
    event ReadInterval(uint256 indexed length);

    //TBA event
    event CreateTokenBoundAccount(
        address indexed user,
        uint256 indexed tokenId,
        string indexed novaId
    );

    //Follower Pass Token
    event CreateFollowerPassToken(
        address indexed owner,
        address indexed boundAccount,
        string indexed symbol,
        string name,
        string imageUri,
        string des
    );
}
