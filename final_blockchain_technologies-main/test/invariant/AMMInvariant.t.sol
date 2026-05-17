// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AMMPool} from "../../contracts/amm/AMMPool.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract AMMInvariantHandler is Test {
    AMMPool public pool;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    address public trader = makeAddr("invariantTrader");

    constructor() {
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");
        pool = new AMMPool(address(tokenA), address(tokenB), address(this));

        tokenA.mint(address(this), 500_000 ether);
        tokenB.mint(address(this), 500_000 ether);
        tokenA.mint(trader, 500_000 ether);
        tokenB.mint(trader, 500_000 ether);

        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);
        pool.addLiquidity(100_000 ether, 200_000 ether, 100_000 ether, 200_000 ether);

        vm.prank(trader);
        tokenA.approve(address(pool), type(uint256).max);
        vm.prank(trader);
        tokenB.approve(address(pool), type(uint256).max);
    }

    function swapA(uint256 amountIn) external {
        amountIn = bound(amountIn, 1, pool.reserveA() / 20);
        if (amountIn == 0) return;

        uint256 kBefore = pool.k();
        uint256 amountOut = pool.getAmountOut(address(tokenA), amountIn);

        vm.prank(trader);
        pool.swapExactTokensForTokens(address(tokenA), amountIn, amountOut, block.timestamp + 1 days);

        assertGe(pool.k(), kBefore);
    }

    function swapB(uint256 amountIn) external {
        amountIn = bound(amountIn, 1, pool.reserveB() / 20);
        if (amountIn == 0) return;

        uint256 kBefore = pool.k();
        uint256 amountOut = pool.getAmountOut(address(tokenB), amountIn);

        vm.prank(trader);
        pool.swapExactTokensForTokens(address(tokenB), amountIn, amountOut, block.timestamp + 1 days);

        assertGe(pool.k(), kBefore);
    }
}

contract AMMInvariantTest is Test {
    AMMInvariantHandler internal handler;

    function setUp() public {
        handler = new AMMInvariantHandler();
        targetContract(address(handler));
    }

    function invariant_ReservesMatchBalances() public view {
        assertGt(handler.pool().k(), 0);
        assertEq(handler.tokenA().balanceOf(address(handler.pool())), handler.pool().reserveA());
        assertEq(handler.tokenB().balanceOf(address(handler.pool())), handler.pool().reserveB());
    }
}
