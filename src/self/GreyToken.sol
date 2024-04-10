// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

// Adapted from https://etherscan.io/token/0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
contract GreyToken {
    string public name     = "Grey Token";
    string public symbol   = "GREY";
    uint8  public decimals = 18;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    function wrap() public payable {
        balanceOf[msg.sender] += msg.value;
    }

    function unwrap(uint256 amount) public {
        (bool success, ) = msg.sender.call{ value: amount }("");
        require(success, "unwrap failed");
        
        balanceOf[msg.sender] -= amount;
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        return true;
    }
}