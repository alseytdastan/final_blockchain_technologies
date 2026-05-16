// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AMMPool} from "../../contracts/amm/AMMPool.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract AMMPoolSwapFuzzTest is Test {
    AMMPool internal pool;
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal trader = makeAddr("trader");

    function setUp() public {
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");
        pool = new AMMPool(address(tokenA), address(tokenB), address(this));

        tokenA.mint(trader, 1_000_000 ether);
        tokenB.mint(trader, 1_000_000 ether);

        tokenA.mint(address(this), 100_000 ether);
        tokenB.mint(address(this), 200_000 ether);

        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);
        pool.addLiquidity(100_000 ether, 200_000 ether, 100_000 ether, 200_000 ether);

        vm.prank(trader);
        tokenA.approve(address(pool), type(uint256).max);
        vm.prank(trader);
        tokenB.approve(address(pool), type(uint256).max);
    }

    function testFuzz_SwapAForBIncreasesK(uint128 amountInRaw) public {
        uint256 reserveA = pool.reserveA();
        uint256 maxIn = reserveA / 10;
        if (maxIn == 0) return;

        uint256 amountIn = bound(uint256(amountInRaw), 1, maxIn);
        uint256 kBefore = pool.k();
        uint256 amountOut = pool.getAmountOut(address(tokenA), amountIn);

        vm.prank(trader);
        pool.swapExactTokensForTokens(address(tokenA), amountIn, amountOut, block.timestamp + 1 hours);

        assertGe(pool.k(), kBefore);
        assertEq(tokenA.balanceOf(address(pool)), pool.reserveA());
        assertEq(tokenB.balanceOf(address(pool)), pool.reserveB());
    }

    function testFuzz_GetAmountOutNeverExceedsReserve(uint128 amountInRaw) public view {
        uint256 reserveA = pool.reserveA();
        uint256 reserveB = pool.reserveB();
        if (reserveA == 0 || reserveB == 0) return;

        uint256 amountIn = bound(uint256(amountInRaw), 1, reserveA);
        uint256 amountOut = pool.getAmountOut(address(tokenA), amountIn);

        assertLt(amountOut, reserveB);
    }
}
