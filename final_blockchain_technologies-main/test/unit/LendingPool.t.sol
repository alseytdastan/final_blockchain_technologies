// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {LendingPool} from "../../contracts/lending/LendingPool.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";
import {MockV3Aggregator} from "../../contracts/oracle/MockV3Aggregator.sol";

contract LendingPoolTest is Test {
    LendingPool internal pool;
    MockERC20 internal collateral;
    MockERC20 internal borrowToken;
    MockV3Aggregator internal feed;

    address internal user = makeAddr("user");
    address internal liquidator = makeAddr("liquidator");

    uint256 internal constant COLLATERAL_PRICE = 2000e8; // $2000, 8 decimals
    uint256 internal constant MAX_LTV_BPS = 7500; // 75%
    uint256 internal constant LIQ_THRESHOLD_BPS = 8000; // 80%
    uint256 internal constant BORROW_RATE_BPS = 1000; // 10% / year
    uint256 internal constant LIQ_BONUS_BPS = 500; // 5%

    function setUp() public {
        collateral = new MockERC20("Collateral", "COL");
        borrowToken = new MockERC20("Borrow USD", "BUSD");
        feed = new MockV3Aggregator(8, int256(COLLATERAL_PRICE));

        pool = new LendingPool(
            address(collateral),
            address(borrowToken),
            address(feed),
            address(this),
            MAX_LTV_BPS,
            LIQ_THRESHOLD_BPS,
            BORROW_RATE_BPS,
            LIQ_BONUS_BPS
        );

        collateral.mint(user, 100 ether);
        borrowToken.mint(address(pool), 1_000_000 ether);
        borrowToken.mint(liquidator, 1_000_000 ether);

        vm.startPrank(user);
        collateral.approve(address(pool), type(uint256).max);
        borrowToken.approve(address(pool), type(uint256).max);
        vm.stopPrank();

        vm.prank(liquidator);
        borrowToken.approve(address(pool), type(uint256).max);
    }

    function testDepositAndBorrowWithinLtv() public {
        vm.startPrank(user);
        pool.depositCollateral(10 ether);

        uint256 maxBorrow = (10 ether * COLLATERAL_PRICE / 1e8) * MAX_LTV_BPS / 10_000;
        pool.borrow(maxBorrow);

        (uint256 col, uint256 principal,) = pool.accounts(user);
        assertEq(col, 10 ether);
        assertGt(principal, 0);
        assertEq(borrowToken.balanceOf(user), maxBorrow);
        vm.stopPrank();
    }

    function testRevertBorrowExceedsLtv() public {
        vm.startPrank(user);
        pool.depositCollateral(10 ether);

        uint256 maxBorrow = (10 ether * COLLATERAL_PRICE / 1e8) * MAX_LTV_BPS / 10_000;
        vm.expectRevert(LendingPool.BorrowExceededLtv.selector);
        pool.borrow(maxBorrow + 1 ether);
        vm.stopPrank();
    }

    function testRepayReducesDebt() public {
        vm.startPrank(user);
        pool.depositCollateral(10 ether);
        pool.borrow(5_000 ether);
        pool.repay(2_000 ether);
        (, uint256 principal,) = pool.accounts(user);
        assertEq(principal, 3_000 ether);
        vm.stopPrank();
    }

    function testLinearInterestAccrues() public {
        vm.startPrank(user);
        pool.depositCollateral(10 ether);
        pool.borrow(1_000 ether);

        uint256 debtBefore = pool.totalDebt(user);
        vm.warp(block.timestamp + 365 days);
        uint256 debtAfter = pool.totalDebt(user);

        assertGt(debtAfter, debtBefore);
        vm.stopPrank();
    }

    function testHealthFactorBelowOneWhenUndercollateralized() public {
        vm.startPrank(user);
        pool.depositCollateral(10 ether);
        pool.borrow(14_000 ether);

        feed.updateAnswer(int256(1000e8)); // price crash

        assertLt(pool.healthFactor(user), 10_000);
        vm.stopPrank();
    }

    function testLiquidateUnhealthyPosition() public {
        vm.startPrank(user);
        pool.depositCollateral(10 ether);
        pool.borrow(14_000 ether);
        feed.updateAnswer(int256(1000e8));
        vm.stopPrank();

        uint256 debt = pool.totalDebt(user);
        uint256 collateralBefore = collateral.balanceOf(liquidator);

        vm.prank(liquidator);
        pool.liquidate(user, debt);

        (, uint256 principalAfter,) = pool.accounts(user);
        assertEq(principalAfter, 0);
        assertGt(collateral.balanceOf(liquidator), collateralBefore);
    }

    function testRevertLiquidateHealthyAccount() public {
        vm.startPrank(user);
        pool.depositCollateral(10 ether);
        pool.borrow(5_000 ether);
        vm.stopPrank();

        vm.prank(liquidator);
        vm.expectRevert(LendingPool.HealthyAccount.selector);
        pool.liquidate(user, 1 ether);
    }

    function testWithdrawCollateralWhenHealthy() public {
        vm.startPrank(user);
        pool.depositCollateral(10 ether);
        pool.borrow(5_000 ether);
        pool.withdrawCollateral(1 ether);
        (uint256 colAfter,,) = pool.accounts(user);
        assertEq(colAfter, 9 ether);
        vm.stopPrank();
    }

    function testRevertWithdrawCollateralBreaksLtv() public {
        vm.startPrank(user);
        pool.depositCollateral(10 ether);
        pool.borrow(14_000 ether);
        feed.updateAnswer(int256(1000e8));
        vm.expectRevert(LendingPool.BorrowExceededLtv.selector);
        pool.withdrawCollateral(1 ether);
        vm.stopPrank();
    }

    function testRevertZeroDeposit() public {
        vm.prank(user);
        vm.expectRevert(LendingPool.ZeroAmount.selector);
        pool.depositCollateral(0);
    }
}
