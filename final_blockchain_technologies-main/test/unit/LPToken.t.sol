// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {LPToken} from "../../contracts/token/LPToken.sol";

contract LPTokenTest is Test {
    LPToken internal token;

    address internal pool = makeAddr("pool");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function setUp() public {
        token = new LPToken(pool);
    }

    function testMetadata() public view {
        assertEq(token.name(), "DeFiHub LP Token");
        assertEq(token.symbol(), "DFH-LP");
        assertEq(token.decimals(), 18);
        assertEq(token.pool(), pool);
    }

    function testMintByPoolIncreasesSupplyAndBalance() public {
        vm.prank(pool);
        token.mint(alice, 100 ether);

        assertEq(token.totalSupply(), 100 ether);
        assertEq(token.balanceOf(alice), 100 ether);
    }

    function testBurnByPoolDecreasesSupplyAndBalance() public {
        vm.startPrank(pool);
        token.mint(alice, 100 ether);
        token.burn(alice, 40 ether);
        vm.stopPrank();

        assertEq(token.totalSupply(), 60 ether);
        assertEq(token.balanceOf(alice), 60 ether);
    }

    function testMintEmitsTransferFromZero() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), bob, 5 ether);

        vm.prank(pool);
        token.mint(bob, 5 ether);
    }

    function testBurnEmitsTransferToZero() public {
        vm.startPrank(pool);
        token.mint(bob, 5 ether);

        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, address(0), 2 ether);
        token.burn(bob, 2 ether);
        vm.stopPrank();
    }

    function testRevertMintWhenCallerIsNotPool() public {
        vm.expectRevert("ONLY_POOL");
        token.mint(alice, 1 ether);
    }

    function testRevertBurnWhenCallerIsNotPool() public {
        vm.prank(pool);
        token.mint(alice, 1 ether);

        vm.expectRevert("ONLY_POOL");
        token.burn(alice, 1 ether);
    }
}
