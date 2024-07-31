// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Batch } from "./lib/Batch.sol";
import { ERC20 } from "./lib/ERC20.sol";
import { RelayReceiver } from "./lib/RelayReceiver.sol";
import { Vault } from "./Vault.sol";

contract Staking is Batch, RelayReceiver {
    string constant public name     = "Stake Token";
    string constant public symbol   = "STK";
    uint8  constant public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    Vault public immutable vault;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address _asset, address _relayer) RelayReceiver(_relayer) {
        vault = new Vault(_asset);
    }

    // ========================================= STAKING FUNCTIONS ========================================

    function stake(uint256 amount) external {
        balanceOf[_msgSender()] += amount;
        totalSupply += amount;
        
        vault.deposit(_msgSender(), amount);
    }

    function unstake(uint256 amount) external {
        balanceOf[_msgSender()] -= amount;
        totalSupply -= amount;
        
        vault.withdraw(_msgSender(), amount);
    }

    // ========================================= ERC20 FUNCTIONS ========================================

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[_msgSender()][spender] = amount;
        
        emit Approval(_msgSender(), spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return transferFrom(_msgSender(), to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        if (from != _msgSender()) allowance[from][_msgSender()] -= amount;

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);

        return true;
    }
}