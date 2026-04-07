// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LPToken {
    string public name = "LP Token";
    string public symbol = "LPT";
    uint8 public decimals = 18;

    uint public totalSupply;
    address public amm;

    mapping(address => uint) public balanceOf;

    modifier onlyAMM() {
        require(msg.sender == amm, "Only AMM");
        _;
    }

    constructor() {
        amm = msg.sender;
    }

    function mint(address to, uint amount) external onlyAMM {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function burn(address from, uint amount) external onlyAMM {
        require(balanceOf[from] >= amount, "Not enough");

        balanceOf[from] -= amount;
        totalSupply -= amount;
    }
}