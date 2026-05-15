// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ProtocolTreasury} from "../../contracts/governance/ProtocolTreasury.sol";

contract ProtocolBootstrapTest is Test {
    ProtocolTreasury internal bootstrap;

    address internal owner = address(0xA11CE);
    address internal nonOwner = address(0xB0B);
    address internal ammAddress = address(0xC0FFEE);

    function setUp() external {
        bootstrap = new ProtocolTreasury(owner);
    }

    function testOwnerIsSet() external view {
        assertEq(bootstrap.owner(), owner);
    }

    function testRegisterModuleByOwner() external {
        vm.prank(owner);
        bootstrap.registerModule(ProtocolTreasury.Module.AMM, ammAddress);

        assertEq(
            bootstrap.moduleAddress(ProtocolTreasury.Module.AMM),
            ammAddress
        );
    }

    function testRevertWhenNonOwnerRegistersModule() external {
        vm.prank(nonOwner);
        vm.expectRevert(ProtocolTreasury.NotOwner.selector);
        bootstrap.registerModule(ProtocolTreasury.Module.AMM, ammAddress);
    }

    function testRevertWhenRegisteringZeroAddress() external {
        vm.prank(owner);
        vm.expectRevert(ProtocolTreasury.ZeroAddress.selector);
        bootstrap.registerModule(ProtocolTreasury.Module.AMM, address(0));
    }

    function testRevertWhenRegisteringSameModuleTwice() external {
        vm.startPrank(owner);
        bootstrap.registerModule(ProtocolTreasury.Module.AMM, ammAddress);

        vm.expectRevert(
            abi.encodeWithSelector(
                ProtocolTreasury.ModuleAlreadySet.selector,
                ProtocolTreasury.Module.AMM
            )
        );
        bootstrap.registerModule(ProtocolTreasury.Module.AMM, address(0x1234));
        vm.stopPrank();
    }
}
