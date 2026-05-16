// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {YieldVault} from "../../contracts/vault/YieldVault.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract YieldVaultTest is Test {
    YieldVault internal vault;
    MockERC20 internal asset;

    address internal user = makeAddr("user");
    address internal other = makeAddr("other");

    function setUp() public {
        asset = new MockERC20("Underlying", "UND");
        vault = new YieldVault(asset, address(this));

        asset.mint(user, 1_000_000 ether);
        asset.mint(other, 1_000_000 ether);

        vm.startPrank(user);
        asset.approve(address(vault), type(uint256).max);
        vm.stopPrank();
        vm.prank(other);
        asset.approve(address(vault), type(uint256).max);

        // Seed vault to avoid empty-vault edge cases in tests.
        asset.mint(address(vault), 1_000 ether);
    }

    function testMetadata() public view {
        assertEq(vault.name(), "DeFiHub Yield Vault");
        assertEq(vault.symbol(), "dhYV");
        assertEq(vault.asset(), address(asset));
    }

    function testDepositMintsShares() public {
        uint256 assets = 100 ether;
        vm.prank(user);
        uint256 shares = vault.deposit(assets, user);

        assertGt(shares, 0);
        assertEq(vault.balanceOf(user), shares);
        assertEq(vault.totalAssets(), 1_000 ether + assets);
    }

    function testMintDepositEquivalence() public {
        uint256 assets = 50 ether;
        uint256 shares = vault.previewDeposit(assets);

        vm.prank(user);
        uint256 assetsUsed = vault.mint(shares, user);
        assertLe(assetsUsed, assets);
        assertGe(assetsUsed, assets - 1 ether);
    }

    function testWithdrawReturnsAssets() public {
        vm.prank(user);
        vault.deposit(100 ether, user);

        vm.prank(user);
        uint256 sharesBurned = vault.withdraw(40 ether, user, user);

        assertGt(sharesBurned, 0);
        assertEq(asset.balanceOf(user), 1_000_000 ether - 100 ether + 40 ether);
    }

    function testRedeemBurnsShares() public {
        vm.prank(user);
        uint256 shares = vault.deposit(100 ether, user);

        vm.prank(user);
        uint256 assets = vault.redeem(shares / 2, user, user);

        assertGt(assets, 0);
        assertLt(vault.balanceOf(user), shares);
    }

    function testRoundTripDepositWithdrawAll() public {
        vm.prank(user);
        uint256 shares = vault.deposit(200 ether, user);

        vm.prank(user);
        uint256 assets = vault.redeem(shares, user, user);

        assertGe(assets, 199 ether);
        assertLe(vault.balanceOf(user), 1);
    }

    function testConvertRoundings() public {
        uint256 assets = 123_456_789_012_345_678;
        uint256 shares = vault.convertToShares(assets);
        uint256 back = vault.convertToAssets(shares);
        assertLe(back, assets);
    }

    function testMaxFunctionsAfterDeposit() public {
        vm.prank(user);
        vault.deposit(10 ether, user);

        assertGt(vault.maxWithdraw(user), 0);
        assertGt(vault.maxRedeem(user), 0);
    }

    function testDepositZeroMintsNoShares() public {
        vm.prank(user);
        assertEq(vault.deposit(0, user), 0);
    }

    function testERC4626Interface() public view {
        assertEq(vault.decimals(), asset.decimals() + 3);
    }
}
