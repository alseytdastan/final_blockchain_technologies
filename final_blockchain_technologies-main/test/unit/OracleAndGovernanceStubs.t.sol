// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PriceOracle} from "../../contracts/oracle/PriceOracle.sol";
import {ProtocolGovernor} from "../../contracts/governance/ProtocolGovernor.sol";
import {ProtocolTimelock} from "../../contracts/governance/ProtocolTimelock.sol";

contract OracleAndGovernanceStubsTest is Test {
    PriceOracle internal oracle;

    address internal eth = makeAddr("eth");
    address internal btc = makeAddr("btc");

    function setUp() public {
        oracle = new PriceOracle();
    }

    function testOracleDefaultPriceIsZero() public view {
        assertEq(oracle.latestPrice(eth), 0);
    }

    function testOracleSetPriceStoresIndependentAssets() public {
        oracle.setPrice(eth, 2_000e8);
        oracle.setPrice(btc, 60_000e8);

        assertEq(oracle.latestPrice(eth), 2_000e8);
        assertEq(oracle.latestPrice(btc), 60_000e8);
    }

    function testOracleSetPriceEmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit PriceOracle.PriceUpdated(eth, 2_000e8);

        oracle.setPrice(eth, 2_000e8);
    }

    function testGovernorName() public {
        ProtocolGovernor governor = new ProtocolGovernor();
        assertEq(governor.name(), "DeFiHub Governor");
    }

    function testTimelockMinDelay() public {
        ProtocolTimelock timelock = new ProtocolTimelock(2 days);
        assertEq(timelock.minDelay(), 2 days);
    }
}
