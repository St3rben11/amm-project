// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract InvariantTest is Test {
    MyToken token;

    function setUp() public {
        token = new MyToken();
        token.mint(address(this), 1000);
    }

    function testInvariant_totalSupplyNeverChanges() public view {
        assertEq(token.totalSupply(), 1000);
    }
}