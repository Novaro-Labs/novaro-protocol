// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library NovaroDataTypes {

    // This struct encapsulates the data associated with a Dynamic Social Token (DST),
    // including the token's level and experience points.
    struct DstData {
        uint256 lv;
        uint256 exp;
        string url;
    }

    // This is the mapping structure for DST, where 'lv' represents the level,
    // 'left' denotes the lower bound (exclusive), and 'right' denotes the upper bound (inclusive).
    struct DstInterval {
        uint256 lv;
        uint256 left;
        uint256 right;
        string url;
    }

}
