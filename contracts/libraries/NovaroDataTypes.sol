// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    //Stake request struct includes the staker address, amount, and chainId
    struct StakeRequest {
        address owner;
        uint256 amount;
        uint256 chainId;
    }

    //Unstake request struct
    struct UnstakeRequest {
        address owner;
        uint256 amount;
        uint chainId;
    }

    //This struct is for storing on-chain stake operations
    struct StakeData {
        address staker;
        uint256 amount;
        uint256 chainId;
    }

    struct FollowerPassTokenData {
        address deployer;
        address boundAccount;
        address token;
        string name;
        string symbol;
        string imageUrl;
        string des;
    }
}
