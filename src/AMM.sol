// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MyToken.sol";
import "./LPToken.sol";

contract AMM {
    MyToken public tokenA;
    MyToken public tokenB;
    LPToken public lpToken;

    uint public reserveA;
    uint public reserveB;

    uint public totalLiquidity;

    // EVENTS
    event LiquidityAdded(address user, uint amountA, uint amountB);
    event LiquidityRemoved(address user, uint amountA, uint amountB);
    event Swap(address user, address tokenIn, uint amountIn, uint amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = MyToken(_tokenA);
        tokenB = MyToken(_tokenB);

        lpToken = new LPToken();
    }

    function addLiquidity(uint amountA, uint amountB) public {
        require(amountA > 0 && amountB > 0, "Zero amount");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint liquidityMinted;

        if (totalLiquidity == 0) {
            liquidityMinted = sqrt(amountA * amountB);
        } else {
            uint liquidityA = (amountA * totalLiquidity) / reserveA;
            uint liquidityB = (amountB * totalLiquidity) / reserveB;
            liquidityMinted = min(liquidityA, liquidityB);
        }

        require(liquidityMinted > 0, "No liquidity");

        lpToken.mint(msg.sender, liquidityMinted);
        totalLiquidity += liquidityMinted;

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    function removeLiquidity(uint amount) public {
        require(lpToken.balanceOf(msg.sender) >= amount, "Not enough LP");

        uint amountA = (amount * reserveA) / totalLiquidity;
        uint amountB = (amount * reserveB) / totalLiquidity;

        lpToken.burn(msg.sender, amount);
        totalLiquidity -= amount;

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    function swap(address tokenIn, uint amountIn, uint minAmountOut) public {
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token");

        bool isA = tokenIn == address(tokenA);

        (MyToken inToken, MyToken outToken, uint reserveIn, uint reserveOut) =
            isA
                ? (tokenA, tokenB, reserveA, reserveB)
                : (tokenB, tokenA, reserveB, reserveA);

        inToken.transferFrom(msg.sender, address(this), amountIn);

        uint amountOut = getAmountOut(amountIn, reserveIn, reserveOut);

        require(amountOut >= minAmountOut, "Slippage too high");

        outToken.transfer(msg.sender, amountOut);

        if (isA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint) {
        uint amountInWithFee = (amountIn * 997) / 1000;
        return (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint x, uint y) internal pure returns (uint) {
        return x < y ? x : y;
    }
}