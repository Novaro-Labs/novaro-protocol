// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mocker is ERC721 {
    constructor() ERC721("ERC721Mocker", "NFTMocker") {
        _safeMint(msg.sender, 1);
    }
}
