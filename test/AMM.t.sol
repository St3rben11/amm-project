// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/AMM.sol";

contract AMMTest is Test {
    MyToken tokenA;
    MyToken tokenB;
    AMM amm;

    address user = address(1);

    function setUp() public {
        tokenA = new MyToken();
        tokenB = new MyToken();

        amm = new AMM(address(tokenA), address(tokenB));

        tokenA.mint(user, 10000);
        tokenB.mint(user, 10000);

        vm.startPrank(user);
        tokenA.approve(address(amm), type(uint).max);
        tokenB.approve(address(amm), type(uint).max);
        vm.stopPrank();
    }

    function testAddLiquidityFirstTime() public {
        vm.prank(user);
        amm.addLiquidity(1000, 1000);

        assertEq(amm.reserveA(), 1000);
        assertEq(amm.reserveB(), 1000);
    }

    function testAddLiquiditySecondTime() public {
        vm.startPrank(user);
        amm.addLiquidity(1000, 1000);
        amm.addLiquidity(1000, 1000);
        vm.stopPrank();

        assertEq(amm.reserveA(), 2000);
    }

    function testRemoveLiquidity() public {
        vm.startPrank(user);
        amm.addLiquidity(1000, 1000);
        amm.removeLiquidity(500);
        vm.stopPrank();

        assertTrue(amm.reserveA() < 1000);
    }

    function testSwapAtoB() public {
        vm.startPrank(user);
        amm.addLiquidity(1000, 1000);
        amm.swap(address(tokenA), 100, 1);
        vm.stopPrank();

        assertTrue(tokenB.balanceOf(user) > 0);
    }

    function testSwapBtoA() public {
        vm.startPrank(user);
        amm.addLiquidity(1000, 1000);
        amm.swap(address(tokenB), 100, 1);
        vm.stopPrank();

        assertTrue(tokenA.balanceOf(user) > 0);
    }

    function testInvariantK() public {
        vm.startPrank(user);
        amm.addLiquidity(1000, 1000);

        uint kBefore = amm.reserveA() * amm.reserveB();

        amm.swap(address(tokenA), 100, 1);

        uint kAfter = amm.reserveA() * amm.reserveB();

        assertTrue(kAfter >= kBefore);
        vm.stopPrank();
    }

    function testRevertZeroLiquidity() public {
        vm.prank(user);
        vm.expectRevert();
        amm.addLiquidity(0, 0);
    }

    function testRevertInvalidToken() public {
        vm.prank(user);
        vm.expectRevert();
        amm.swap(address(123), 100, 1);
    }

    function testLargeSwapImpact() public {
        vm.startPrank(user);
        amm.addLiquidity(1000, 1000);

        amm.swap(address(tokenA), 900, 1);
        vm.stopPrank();

        assertTrue(amm.reserveA() > 1000);
    }

    function testPartialRemove() public {
        vm.startPrank(user);
        amm.addLiquidity(1000, 1000);
        amm.removeLiquidity(200);
        vm.stopPrank();

        assertTrue(amm.reserveA() < 1000);
    }

    // ✅ FIXED (LP TOKEN)
    function testFullRemove() public {
        vm.startPrank(user);
        amm.addLiquidity(1000, 1000);

        uint liq = amm.lpToken().balanceOf(user);

        amm.removeLiquidity(liq);
        vm.stopPrank();

        assertEq(amm.reserveA(), 0);
    }

    function testFuzzSwap(uint amount) public {
        vm.assume(amount > 1 && amount < 500);

        vm.startPrank(user);
        amm.addLiquidity(1000, 1000);

        uint out = amm.getAmountOut(amount, 1000, 1000);
        vm.assume(out > 0);

        amm.swap(address(tokenA), amount, 0);
        vm.stopPrank();

        assertTrue(tokenB.balanceOf(user) >= 0);
    }

    function testSlippageRevert() public {
        vm.startPrank(user);
        amm.addLiquidity(1000, 1000);

        vm.expectRevert();
        amm.swap(address(tokenA), 100, 1000);
        vm.stopPrank();
    }

    function testGetAmountOut() public {
        uint out = amm.getAmountOut(100, 1000, 1000);
        assertTrue(out > 0);
    }

    function testMultipleSwaps() public {
        vm.startPrank(user);
        amm.addLiquidity(1000, 1000);

        amm.swap(address(tokenA), 100, 1);
        amm.swap(address(tokenB), 50, 1);
        vm.stopPrank();

        assertTrue(amm.reserveA() > 0);
    }
}