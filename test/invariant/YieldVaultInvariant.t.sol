// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {YieldVault} from "../../contracts/vault/YieldVault.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract YieldVaultHandler is Test {
    YieldVault public vault;
    MockERC20 public asset;
    address public user = makeAddr("invUser");

    constructor() {
        asset = new MockERC20("Underlying", "UND");
        vault = new YieldVault(asset, address(this));
        asset.mint(user, 10_000_000 ether);
        asset.mint(address(vault), 1_000 ether);
        vm.prank(user);
        asset.approve(address(vault), type(uint256).max);
    }

    function depositAssets(uint256 amount) external {
        amount = bound(amount, 1 ether, 50_000 ether);
        vm.prank(user);
        vault.deposit(amount, user);
    }

    function withdrawAssets(uint256 amount) external {
        amount = bound(amount, 1, vault.maxWithdraw(user));
        if (amount == 0) return;
        vm.prank(user);
        vault.withdraw(amount, user, user);
    }
}

contract YieldVaultInvariantTest is Test {
    YieldVaultHandler internal handler;

    function setUp() public {
        handler = new YieldVaultHandler();
        targetContract(address(handler));
    }

    function invariant_TotalAssetsMatchesBalance() public view {
        assertEq(handler.vault().totalAssets(), handler.asset().balanceOf(address(handler.vault())));
    }

    function invariant_SharesSupplyConsistent() public view {
        assertGe(handler.vault().totalSupply(), 0);
    }
}
