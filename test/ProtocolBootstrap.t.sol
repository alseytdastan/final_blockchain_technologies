// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ProtocolBootstrap} from "../src/ProtocolBootstrap.sol";

contract ProtocolBootstrapTest is Test {
    ProtocolBootstrap internal bootstrap;

    address internal owner = address(0xA11CE);
    address internal nonOwner = address(0xB0B);
    address internal ammAddress = address(0xC0FFEE);

    function setUp() external {
        bootstrap = new ProtocolBootstrap(owner);
    }

    function testOwnerIsSet() external view {
        assertEq(bootstrap.owner(), owner);
    }

    function testRegisterModuleByOwner() external {
        vm.prank(owner);
        bootstrap.registerModule(ProtocolBootstrap.Module.AMM, ammAddress);

        assertEq(
            bootstrap.moduleAddress(ProtocolBootstrap.Module.AMM),
            ammAddress
        );
    }

    function testRevertWhenNonOwnerRegistersModule() external {
        vm.prank(nonOwner);
        vm.expectRevert(ProtocolBootstrap.NotOwner.selector);
        bootstrap.registerModule(ProtocolBootstrap.Module.AMM, ammAddress);
    }

    function testRevertWhenRegisteringZeroAddress() external {
        vm.prank(owner);
        vm.expectRevert(ProtocolBootstrap.ZeroAddress.selector);
        bootstrap.registerModule(ProtocolBootstrap.Module.AMM, address(0));
    }

    function testRevertWhenRegisteringSameModuleTwice() external {
        vm.startPrank(owner);
        bootstrap.registerModule(ProtocolBootstrap.Module.AMM, ammAddress);

        vm.expectRevert(
            abi.encodeWithSelector(
                ProtocolBootstrap.ModuleAlreadySet.selector,
                ProtocolBootstrap.Module.AMM
            )
        );
        bootstrap.registerModule(ProtocolBootstrap.Module.AMM, address(0x1234));
        vm.stopPrank();
    }
}
