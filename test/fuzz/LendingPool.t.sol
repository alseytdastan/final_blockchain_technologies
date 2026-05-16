// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {LendingPool} from "../../contracts/lending/LendingPool.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";
import {MockV3Aggregator} from "../../contracts/oracle/MockV3Aggregator.sol";

contract LendingPoolFuzzTest is Test {
    LendingPool internal pool;
    MockERC20 internal collateral;
    MockERC20 internal borrowToken;

    address internal user = makeAddr("fuzzUser");

    function setUp() public {
        collateral = new MockERC20("Collateral", "COL");
        borrowToken = new MockERC20("Borrow USD", "BUSD");
        MockV3Aggregator feed = new MockV3Aggregator(8, int256(2000e8));

        pool = new LendingPool(
            address(collateral), address(borrowToken), address(feed), address(this), 7500, 8000, 1000, 500
        );

        collateral.mint(user, 10_000 ether);
        borrowToken.mint(address(pool), 10_000_000 ether);

        vm.startPrank(user);
        collateral.approve(address(pool), type(uint256).max);
        borrowToken.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function testFuzz_BorrowWithinLtv(uint96 collateralAmount, uint96 borrowFractionBps) public {
        collateralAmount = uint96(bound(uint256(collateralAmount), 1 ether, 1000 ether));
        borrowFractionBps = uint96(bound(uint256(borrowFractionBps), 1, 7500));

        vm.startPrank(user);
        pool.depositCollateral(collateralAmount);

        uint256 maxBorrow = (uint256(collateralAmount) * 2000e8 / 1e8) * 7500 / 10_000;
        uint256 borrowAmount = (maxBorrow * borrowFractionBps) / 10_000;
        if (borrowAmount == 0) return;

        pool.borrow(borrowAmount);
        (, uint256 principal,) = pool.accounts(user);
        assertLe(principal, maxBorrow);
        vm.stopPrank();
    }
}
