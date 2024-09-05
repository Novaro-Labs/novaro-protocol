// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface INovaroClient is IERC721Receiver {
    function onDelegateReceived(string calldata novaId) external;

    function createTokenBoundAccount(
        address owner,
        string calldata novaId
    ) external;
}
