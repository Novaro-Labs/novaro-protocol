// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library NovaroEvents {

    event OnChainFeed(uint256 indexed tokenId, uint256 indexed exp);
    event OffChainFeed(uint256 indexed tokenId, uint256 indexed exp);
    event ReadInterval(uint256 indexed length);

}
