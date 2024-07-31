// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { IERC20 } from "./interfaces/IERC20.sol";
import { IFlashloanCallback } from "./interfaces/IFlashloanCallback.sol";

contract Vault {
    IERC20 public token;

    mapping(address => uint256) public depositAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function deposit(address from, uint256 amount) external {
        depositAmount[msg.sender] += amount;
        token.transferFrom(from, address(this), amount);
    }

    function withdraw(address to, uint256 amount) external {
        depositAmount[msg.sender] -= amount;
        token.transfer(to, amount);
    }

    function flashLoan(uint256 amount, bytes calldata data) external {
        token.transfer(msg.sender, amount);

        IFlashloanCallback(msg.sender).onFlashLoan(amount, data);

        token.transferFrom(msg.sender, address(this), amount);
    }
}