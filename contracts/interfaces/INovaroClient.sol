// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface INovaroClient is IERC721Receiver {

    function createFollowerPassToken(
        string calldata name,
        string calldata symbol,
        string calldata imageUrl,
        string calldata des,
        address _boundAccount
    ) external;
}
