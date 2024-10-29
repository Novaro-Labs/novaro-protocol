// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {NovaroEvents} from "../libraries/NovaroEvents.sol";
import {NovaroErrors} from "../libraries/NovaroErrors.sol";
contract FollowerPassToken is ERC20 {
    string public constant NAME = "FollowerPass Token";

    constructor(
        string memory name,
        string memory symbol,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, 10 ** 18);
    }

    function sell(address _pool, uint256 _amount) external {
        if (address(_pool) == address(0)) {
            revert NovaroErrors.InvalidAddress();
        }
        super.transfer(_pool, _amount);
        emit NovaroEvents.SellFollowerPassToken(msg.sender, address(this), _amount);
    }

    function buy(address _pool, uint256 _amount) external {
        if (address (_pool) == address(0)) {
            revert NovaroErrors.InvalidAddress();
        }
        super.transfer()(_pool, msg.sender, _amount);
        emit NovaroEvents.BuyFollowerPassToken(_pool, msg.sender, _amount);
    }
}
