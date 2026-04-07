// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint);
}

contract ForkTest is Test {
    IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    function testUSDCBalance() public {
        address whale = 0x55FE002aefF02F77364de339a1292923A15844B8;

        uint balance = USDC.balanceOf(whale);

        assertGt(balance, 0);
    }
}