// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {YieldVault} from "../../contracts/vault/YieldVault.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract YieldVaultFuzzTest is Test {
    YieldVault internal vault;
    MockERC20 internal asset;
    address internal user = makeAddr("vaultUser");

    function setUp() public {
        asset = new MockERC20("Underlying", "UND");
        vault = new YieldVault(asset, address(this));
        asset.mint(user, 1_000_000 ether);
        asset.mint(address(vault), 1_000 ether);
        vm.prank(user);
        asset.approve(address(vault), type(uint256).max);
    }

    function testFuzz_DepositWithdrawMatchesPreview(uint256 amount) public {
        amount = bound(amount, 100 ether, 100_000 ether);

        vm.startPrank(user);
        vault.deposit(amount, user);
        uint256 shares = vault.maxRedeem(user);
        uint256 expected = vault.previewRedeem(shares);
        uint256 assetsOut = vault.redeem(shares, user, user);
        vm.stopPrank();

        assertEq(assetsOut, expected);
        assertLe(assetsOut, amount);
    }

    function testFuzz_ConvertToSharesNeverOverstates(uint96 amount) public {
        amount = uint96(bound(uint256(amount), 1, 1_000_000 ether));
        uint256 shares = vault.convertToShares(amount);
        assertLe(vault.convertToAssets(shares), amount);
    }
}
