// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AMMPool} from "../../contracts/amm/AMMPool.sol";
import {GovernanceToken} from "../../contracts/token/GovernanceToken.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";
import {YieldVault} from "../../contracts/vault/YieldVault.sol";

contract AdditionalProtocolFuzzTest is Test {
    AMMPool internal pool;
    GovernanceToken internal governanceToken;
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;
    MockERC20 internal asset;
    YieldVault internal vault;

    address internal trader = makeAddr("trader");
    address internal vaultUser = makeAddr("vaultUser");
    address internal voter = makeAddr("voter");
    address internal delegatee = makeAddr("delegatee");

    function setUp() public {
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

        vm.startPrank(trader);
        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);
        vm.stopPrank();

        asset = new MockERC20("Underlying", "UND");
        vault = new YieldVault(asset, address(this));
        asset.mint(vaultUser, 1_000_000 ether);
        vm.prank(vaultUser);
        asset.approve(address(vault), type(uint256).max);

        governanceToken = new GovernanceToken(address(this));
    }

    function testFuzz_SwapBForAIncreasesK(uint96 rawAmountIn) public {
        uint256 amountIn = bound(uint256(rawAmountIn), 1, pool.reserveB() / 10);
        uint256 kBefore = pool.k();
        uint256 amountOut = pool.getAmountOut(address(tokenB), amountIn);

        vm.prank(trader);
        pool.swapExactTokensForTokens(address(tokenB), amountIn, amountOut, block.timestamp + 1 hours);

        assertGe(pool.k(), kBefore);
    }

    function testFuzz_VaultMintRedeemRoundTrip(uint96 rawShares) public {
        uint256 shares = bound(uint256(rawShares), 1 ether, 10_000 ether);
        uint256 assets = vault.previewMint(shares);

        vm.startPrank(vaultUser);
        uint256 assetsIn = vault.mint(shares, vaultUser);
        uint256 expectedAssetsOut = vault.previewRedeem(shares);
        uint256 assetsOut = vault.redeem(shares, vaultUser, vaultUser);
        vm.stopPrank();

        assertEq(assetsIn, assets);
        assertEq(assetsOut, expectedAssetsOut);
    }

    function testFuzz_GovernanceVotingPowerTracksSelfDelegatedMint(uint96 rawAmount) public {
        uint256 amount = bound(uint256(rawAmount), 1, 1_000_000 ether);

        governanceToken.mint(voter, amount);
        vm.prank(voter);
        governanceToken.delegate(voter);

        assertEq(governanceToken.getVotes(voter), amount);
    }

    function testFuzz_GovernanceVotingPowerMovesToDelegatee(uint96 rawAmount) public {
        uint256 amount = bound(uint256(rawAmount), 1, 1_000_000 ether);

        governanceToken.mint(voter, amount);
        vm.prank(voter);
        governanceToken.delegate(delegatee);

        assertEq(governanceToken.getVotes(voter), 0);
        assertEq(governanceToken.getVotes(delegatee), amount);
    }
}
