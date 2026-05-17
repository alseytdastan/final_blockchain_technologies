// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AMMPool} from "../../contracts/amm/AMMPool.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract AMMPoolTest is Test {
    AMMPool internal pool;
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal lp = makeAddr("lp");
    address internal trader = makeAddr("trader");

    uint256 internal constant INITIAL_A = 10_000 ether;
    uint256 internal constant INITIAL_B = 20_000 ether;

    function setUp() public {
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");
        pool = new AMMPool(address(tokenA), address(tokenB), address(this));

        tokenA.mint(lp, 1_000_000 ether);
        tokenB.mint(lp, 1_000_000 ether);
        tokenA.mint(trader, 1_000_000 ether);
        tokenB.mint(trader, 1_000_000 ether);

        vm.startPrank(lp);
        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);
        pool.addLiquidity(INITIAL_A, INITIAL_B, INITIAL_A, INITIAL_B);
        vm.stopPrank();

        vm.startPrank(trader);
        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function testPoolMetadata() public view {
        assertEq(pool.tokenA(), address(tokenA));
        assertEq(pool.tokenB(), address(tokenB));
        assertEq(pool.reserveA(), INITIAL_A);
        assertEq(pool.reserveB(), INITIAL_B);
        assertEq(pool.FEE_NUMERATOR(), 997);
        assertEq(pool.FEE_DENOMINATOR(), 1000);
    }

    function testFirstMintMintsLpTokens() public view {
        assertGt(pool.lpToken().totalSupply(), 0);
        assertGt(pool.lpToken().balanceOf(lp), 0);
    }

    function testAddLiquidityIncreasesReserves() public {
        uint256 reserveABefore = pool.reserveA();
        uint256 reserveBBefore = pool.reserveB();

        vm.startPrank(lp);
        pool.addLiquidity(1_000 ether, 2_000 ether, 900 ether, 1_800 ether);
        vm.stopPrank();

        assertGt(pool.reserveA(), reserveABefore);
        assertGt(pool.reserveB(), reserveBBefore);
    }

    function testSwapExactAForB() public {
        uint256 amountIn = 100 ether;
        uint256 expectedOut = pool.getAmountOut(address(tokenA), amountIn);

        uint256 balanceBBefore = tokenB.balanceOf(trader);

        vm.prank(trader);
        uint256 amountOut =
            pool.swapExactTokensForTokens(address(tokenA), amountIn, expectedOut, block.timestamp + 1 hours);

        assertEq(amountOut, expectedOut);
        assertEq(tokenB.balanceOf(trader), balanceBBefore + amountOut);
        assertEq(pool.reserveA(), INITIAL_A + amountIn);
        assertEq(pool.reserveB(), INITIAL_B - amountOut);
    }

    function testSwapExactBForA() public {
        uint256 amountIn = 200 ether;
        uint256 expectedOut = pool.getAmountOut(address(tokenB), amountIn);

        vm.prank(trader);
        uint256 amountOut =
            pool.swapExactTokensForTokens(address(tokenB), amountIn, expectedOut, block.timestamp + 1 hours);

        assertEq(amountOut, expectedOut);
        assertEq(pool.reserveB(), INITIAL_B + amountIn);
        assertEq(pool.reserveA(), INITIAL_A - amountOut);
    }

    function testSwapIncreasesK() public {
        uint256 kBefore = pool.k();
        uint256 amountIn = 50 ether;
        uint256 amountOut = pool.getAmountOut(address(tokenA), amountIn);

        vm.prank(trader);
        pool.swapExactTokensForTokens(address(tokenA), amountIn, amountOut, block.timestamp + 1 hours);

        assertGe(pool.k(), kBefore);
    }

    function testRevertSwapInsufficientOutput() public {
        uint256 amountIn = 10 ether;
        uint256 expectedOut = pool.getAmountOut(address(tokenA), amountIn);

        vm.prank(trader);
        vm.expectRevert(AMMPool.InsufficientOutputAmount.selector);
        pool.swapExactTokensForTokens(address(tokenA), amountIn, expectedOut + 1, block.timestamp + 1 hours);
    }

    function testRevertSwapExpiredDeadline() public {
        uint256 amountIn = 10 ether;
        uint256 amountOut = pool.getAmountOut(address(tokenA), amountIn);

        vm.warp(block.timestamp + 2 hours);

        vm.prank(trader);
        vm.expectRevert(AMMPool.Expired.selector);
        pool.swapExactTokensForTokens(address(tokenA), amountIn, amountOut, block.timestamp - 1);
    }

    function testRevertSwapZeroAmount() public {
        vm.prank(trader);
        vm.expectRevert(AMMPool.ZeroAmount.selector);
        pool.swapExactTokensForTokens(address(tokenA), 0, 0, block.timestamp + 1 hours);
    }

    function testRevertSwapInvalidToken() public {
        MockERC20 other = new MockERC20("Other", "OTH");
        other.mint(trader, 100 ether);
        vm.prank(trader);
        other.approve(address(pool), type(uint256).max);

        vm.prank(trader);
        vm.expectRevert(AMMPool.InvalidToken.selector);
        pool.swapExactTokensForTokens(address(other), 1 ether, 0, block.timestamp + 1 hours);
    }

    function testRemoveLiquidity() public {
        uint256 lpBalance = pool.lpToken().balanceOf(lp);
        uint256 liquidityToBurn = lpBalance / 4;

        uint256 balanceABefore = tokenA.balanceOf(lp);
        uint256 balanceBBefore = tokenB.balanceOf(lp);

        vm.prank(lp);
        (uint256 amountA, uint256 amountB) = pool.removeLiquidity(liquidityToBurn, 0, 0);

        assertGt(amountA, 0);
        assertGt(amountB, 0);
        assertEq(tokenA.balanceOf(lp), balanceABefore + amountA);
        assertEq(tokenB.balanceOf(lp), balanceBBefore + amountB);
    }

    function testRevertRemoveLiquidityInsufficientOutput() public {
        uint256 lpBalance = pool.lpToken().balanceOf(lp);

        vm.prank(lp);
        vm.expectRevert(AMMPool.InsufficientLiquidity.selector);
        pool.removeLiquidity(lpBalance, type(uint256).max, type(uint256).max);
    }

    function testRevertAddLiquidityZeroAmount() public {
        vm.prank(lp);
        vm.expectRevert(AMMPool.ZeroAmount.selector);
        pool.addLiquidity(0, 100 ether, 0, 0);
    }

    function testKView() public view {
        assertEq(pool.k(), INITIAL_A * INITIAL_B);
    }

    function testRevertGetAmountOutInvalidToken() public {
        vm.expectRevert(AMMPool.InvalidToken.selector);
        pool.getAmountOut(address(0xBEEF), 1 ether);
    }

    function testAddLiquidityUsesOptimalAmountBranch() public {
        vm.prank(lp);
        (uint256 amountA, uint256 amountB,) = pool.addLiquidity(200 ether, 100 ether, 40 ether, 40 ether);

        assertEq(amountA, 50 ether);
        assertEq(amountB, 100 ether);
    }

    function testRevertRemoveLiquidityZero() public {
        vm.prank(lp);
        vm.expectRevert(AMMPool.ZeroAmount.selector);
        pool.removeLiquidity(0, 0, 0);
    }

    function testRevertGetAmountOutOnEmptySide() public {
        AMMPool emptyPool = new AMMPool(address(tokenA), address(tokenB), address(this));
        vm.expectRevert(AMMPool.InsufficientLiquidity.selector);
        emptyPool.getAmountOut(address(tokenA), 1 ether);
    }

    function testGetAmountOutMatchesManualFormula() public view {
        uint256 amountIn = 123 ether;
        uint256 reserveIn = pool.reserveA();
        uint256 reserveOut = pool.reserveB();

        uint256 amountInWithFee = amountIn * 997;
        uint256 expected = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);

        assertEq(pool.getAmountOut(address(tokenA), amountIn), expected);
    }
}
