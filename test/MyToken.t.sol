// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;

    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        token = new MyToken();

        // 👇 mint делает owner (это контракт теста)
        token.mint(user1, 1000);
    }

    function testMint() public {
        token.mint(user2, 500);
        assertEq(token.balanceOf(user2), 500);
    }

    function testTransfer() public {
        vm.prank(user1);
        token.transfer(user2, 200);

        assertEq(token.balanceOf(user2), 200);
    }

    function testApproveAndTransferFrom() public {
        vm.prank(user1);
        token.approve(address(this), 300);

        token.transferFrom(user1, user2, 300);

        assertEq(token.balanceOf(user2), 300);
    }

    // ❌ старый testFail удалили
    // ✅ новый формат
    function test_RevertIf_TransferTooMuch() public {
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 2000);
    }

    function testFuzzTransfer(uint amount) public {
        vm.assume(amount <= 1000);

        vm.prank(user1);
        token.transfer(user2, amount);

        assertEq(token.balanceOf(user2), amount);
    }
}