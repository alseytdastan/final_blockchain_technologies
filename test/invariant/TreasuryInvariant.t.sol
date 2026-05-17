// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ProtocolTreasury} from "../../contracts/governance/ProtocolTreasury.sol";

contract TreasuryInvariantHandler is Test {
    ProtocolTreasury public treasury;

    address public owner = makeAddr("owner");
    address public lastAmm;
    address public lastLending;
    address public lastVault;

    constructor() {
        treasury = new ProtocolTreasury(owner);
    }

    function registerAmm(address moduleAddress) external {
        moduleAddress = _validModuleAddress(moduleAddress);
        if (treasury.moduleAddress(ProtocolTreasury.Module.AMM) != address(0)) return;

        vm.prank(owner);
        treasury.registerModule(ProtocolTreasury.Module.AMM, moduleAddress);
        lastAmm = moduleAddress;
    }

    function registerLending(address moduleAddress) external {
        moduleAddress = _validModuleAddress(moduleAddress);
        if (treasury.moduleAddress(ProtocolTreasury.Module.Lending) != address(0)) return;

        vm.prank(owner);
        treasury.registerModule(ProtocolTreasury.Module.Lending, moduleAddress);
        lastLending = moduleAddress;
    }

    function registerVault(address moduleAddress) external {
        moduleAddress = _validModuleAddress(moduleAddress);
        if (treasury.moduleAddress(ProtocolTreasury.Module.Vault4626) != address(0)) return;

        vm.prank(owner);
        treasury.registerModule(ProtocolTreasury.Module.Vault4626, moduleAddress);
        lastVault = moduleAddress;
    }

    function _validModuleAddress(address moduleAddress) internal pure returns (address) {
        uint160 value = uint160(moduleAddress);
        if (value == 0) return address(1);
        return moduleAddress;
    }
}

contract TreasuryInvariantTest is Test {
    TreasuryInvariantHandler internal handler;

    function setUp() public {
        handler = new TreasuryInvariantHandler();
        targetContract(address(handler));
    }

    function invariant_TreasuryOwnerNeverChanges() public view {
        assertEq(handler.treasury().owner(), handler.owner());
    }

    function invariant_TreasuryAccountingMatchesRegisteredModules() public view {
        assertEq(handler.treasury().moduleAddress(ProtocolTreasury.Module.AMM), handler.lastAmm());
        assertEq(handler.treasury().moduleAddress(ProtocolTreasury.Module.Lending), handler.lastLending());
        assertEq(handler.treasury().moduleAddress(ProtocolTreasury.Module.Vault4626), handler.lastVault());
    }
}
