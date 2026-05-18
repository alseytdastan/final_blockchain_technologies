// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ProtocolTreasury} from "../../contracts/governance/ProtocolTreasury.sol";

contract TreasuryOwnershipTest is Test {
    ProtocolTreasury treasury;

    function setUp() public {
        // Deploy treasury with this test contract as the initial owner
        treasury = new ProtocolTreasury(address(this));
    }

    function test_transferOwnership_toTimelock() public {
        address timelock = address(0xBEEF);
        treasury.transferOwnership(timelock);
        assertEq(treasury.owner(), timelock, "treasury owner should be timelock");
    }
}
