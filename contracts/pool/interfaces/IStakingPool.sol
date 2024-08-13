// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../libraries/NovaroDataTypes.sol";

/**
 * @title IStakingPool
 * @dev Interface for managing staking and withdrawal operations, with records maintained on-chain.
 */
interface IStakingPool {

    /**
     * @dev Records a staking request on the blockchain. This function accepts a `StakeRequest` object,
     * which contains details such as the staker's address, the amount staked, and the chain ID.
     *
     * @param stakeRequest The data structure containing information about the staking operation.
     */
    function stake(NovaroDataTypes.StakeRequest memory stakeRequest) external;

    /**
     * @dev Records a withdrawal request on the blockchain. This function accepts an `UnstakeRequest` object,
     * which contains details such as the staker's address, the amount to be withdrawn, and the chain ID.
     *
     * @param stakeEntry The data structure containing information about the withdrawal operation.
     */
    function withdraw(NovaroDataTypes.UnstakeRequest memory stakeEntry) external;
}