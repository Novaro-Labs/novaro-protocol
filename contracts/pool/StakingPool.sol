// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IStakingPool} from "./interfaces/IStakingPool.sol";
import {NovaroErrors} from "../libraries/NovaroErrors.sol";
import {NovaroEvents} from "../libraries/NovaroEvents.sol";
import {NovaroDataTypes} from "../libraries/NovaroDataTypes.sol";


/*
 * @title: StakingPool
 * @dev: This contract is used to manage the staking of users on multiple chains.
 */
contract StakingPool is IStakingPool {
    // Mapping of user addresses to their staking data
    mapping(address => NovaroDataTypes.StakeData) internal stakeData;

    function stake(NovaroDataTypes.StakeRequest memory stakeRequest) external {
        NovaroDataTypes.StakeData storage userStakeData = stakeData[stakeRequest.owner];
        // If the user has not staked before, initiate the stake
        if (userStakeData.staker == address (0)) {
            _initiateStake(stakeRequest);
            emit NovaroEvents.InitiateStake(stakeRequest.owner, stakeRequest.chainId, userStakeData.amount);
        } else {
            // If the user has already staked, update the stake amount
            // Only the owner of the previous stake can update the stake amount
            require( stakeRequest.owner == msg.sender, "StakingPool: Stake Unauthorized");
            // Verify that the chainId matches
            require( stakeRequest.chainId == userStakeData.chainId, "StakingPool: ChainId Mismatch");
            userStakeData.amount += stakeRequest.amount;
            emit NovaroEvents.Stake(stakeRequest.owner, stakeRequest.chainId, userStakeData.amount);
        }
    }


    function withdraw(NovaroDataTypes.UnstakeRequest memory unstakeRequest) external {
        address owner = unstakeRequest.owner;
        NovaroDataTypes.StakeData storage userStakeData = stakeData[owner];
        // Verify that the user has staked
        require(userStakeData.staker!= address(0), "StakingPool: NotStaked");
        // Verify that the chainId matches
        require(unstakeRequest.chainId == userStakeData.chainId, "StakingPool: ChainId Mismatch");
        // Verify that the user has enough balance to withdraw
        require(userStakeData.amount >= unstakeRequest.amount, "StakingPool: InsufficientBalance");
        userStakeData.amount -= unstakeRequest.amount;
        emit NovaroEvents.UnStake(owner, unstakeRequest.chainId, userStakeData.amount);
    }

    function _initiateStake(NovaroDataTypes.StakeRequest memory stakeRequest)  internal{
        NovaroDataTypes.StakeData storage userStakeData = stakeData[msg.sender];
        userStakeData.staker = stakeRequest.owner;
        userStakeData.chainId = stakeRequest.chainId;
        userStakeData.amount = stakeRequest.amount;
    }
}
