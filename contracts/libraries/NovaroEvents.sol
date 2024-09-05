// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library NovaroEvents {
    //DST events
    event OnChainFeed(uint256 indexed tokenId, uint256 indexed exp);
    event OffChainFeed(uint256 indexed tokenId, uint256 indexed exp);
    event ReadInterval(uint256 indexed length);

    //Stake events
    event Stake(
        address indexed user,
        uint256 indexed chainId,
        uint256 indexed amount
    );
    event InitiateStake(
        address indexed user,
        uint256 indexed chainId,
        uint256 indexed amount
    );
    event UnStake(
        address indexed user,
        uint256 indexed chainId,
        uint256 indexed amount
    );

    //TBA event
    event CreateTokenBoundAccount(
        address indexed user,
        uint256 indexed tokenId,
        string indexed novaId
    );
}
