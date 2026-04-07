// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external returns (bool);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract UniswapForkTest is Test {
    // Corrected Checksummed Addresses
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    // Corrected Checksum for Uniswap V2 Router
    IUniswapV2Router public constant router =
        IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // USDC Whale address for forking
    address public constant whale = 0x55FE002aefF02F77364de339a1292923A15844B8;

    function testSwapUSDCtoWETH() public {
        // Impersonate the whale
        vm.startPrank(whale);

        uint amountIn = 1000 * 1e6; // 1,000 USDC (USDC has 6 decimals)

        // 1. Approve the router to spend USDC
        USDC.approve(address(router), amountIn);

        // 2. Setup the swap path (USDC -> WETH)
        address[] memory path = new address[](2);
        path[0] = address(USDC);
        path[1] = address(WETH);

        // 3. Execute the swap
        router.swapExactTokensForTokens(
            amountIn,
            0, // amountOutMin: 0 for testing, use a slippage calc in production
            path,
            whale,
            block.timestamp
        );

        // 4. Verify WETH balance increased
        uint wethBalance = WETH.balanceOf(whale);
        assertGt(wethBalance, 0);

        vm.stopPrank();
    }
}