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
        string sourceId,
        string des
    );

    //Token Bound Account
    event AccountAlreadyBound(address indexed owner, address indexed boundAccount);
    event CreateAccount(address indexed owner, address indexed boundAccount);

    event SellFollowerPassToken(
        address indexed seller,
        address indexed pool,
        uint256 indexed amount
    );

    event BuyFollowerPassToken(
        address indexed pool,
        address indexed buyer,
        uint256 indexed amount
    );

}
