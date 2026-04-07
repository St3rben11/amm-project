// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LendingPool.sol";
import "../src/MyToken.sol"; // Ensure this path is correct

contract LendingTest is Test {
    LendingPool pool;
    MyToken token;

    address user = address(1);
    address liquidator = address(2);

    function setUp() public {
        token = new MyToken();
        pool = new LendingPool(address(token));

        token.mint(user, 1000 ether);
        token.mint(liquidator, 1000 ether);

        // Pre-approve pool for both users
        vm.prank(user);
        token.approve(address(pool), type(uint256).max);

        vm.prank(liquidator);
        token.approve(address(pool), type(uint256).max);
    }

    function testDeposit() public {
        vm.prank(user);
        pool.deposit(100 ether);
        assertEq(pool.collateral(user), 100 ether);
    }

    function testBorrow() public {
        vm.startPrank(user);
        pool.deposit(100 ether);
        pool.borrow(75 ether); // Max borrow
        assertEq(pool.debt(user), 75 ether);
        vm.stopPrank();
    }

    function testRepay() public {
        vm.startPrank(user);
        pool.deposit(100 ether);
        pool.borrow(50 ether);
        pool.repay(50 ether);
        assertEq(pool.debt(user), 0);
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user);
        pool.deposit(100 ether);
        pool.borrow(50 ether);
        pool.repay(50 ether);
        pool.withdraw(100 ether);
        assertEq(pool.collateral(user), 0);
        vm.stopPrank();
    }

    function testLiquidation() public {
        // 1. User deposits 100 and borrows 75
        vm.startPrank(user);
        pool.deposit(100 ether);
        pool.borrow(75 ether);
        vm.stopPrank();

        // 2. Manipulate storage to make user underwater (Debt > 75% of Collateral)
        // Mapping key for debt[user] at Slot 1: keccak256(abi.encode(user, uint256(1)))
        bytes32 debtSlot = keccak256(abi.encode(user, uint256(1)));
        
        // Inject 80 ether debt into the storage slot
        vm.store(address(pool), debtSlot, bytes32(uint256(80 ether)));

        // 3. Liquidator acts 
        // Liquidator must pay 40 ether (half of 80) to get 50 ether collateral
        vm.prank(liquidator);
        pool.liquidate(user);

        // 4. Assertions
        assertEq(pool.debt(user), 40 ether);     // 80 / 2 = 40
        assertEq(pool.collateral(user), 50 ether); // 100 / 2 = 50
    }
    function testInterestAccrual() public {
       vm.startPrank(user);

       pool.deposit(100 ether);
       pool.borrow(50 ether);

       vm.warp(block.timestamp + 365 days);

       pool.repay(1 ether); // триггер процентов

       assertGt(pool.debt(user), 50 ether);

       vm.stopPrank();
    }
}