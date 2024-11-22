// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ISocialOracle {

    function getSocialScore(address user) external view returns (uint256);

}