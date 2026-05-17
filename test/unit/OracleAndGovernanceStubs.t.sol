// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PriceOracle} from "../../contracts/oracle/PriceOracle.sol";
import {ChainlinkPriceFeed} from "../../contracts/oracle/ChainlinkPriceFeed.sol";
import {MockV3Aggregator} from "../../contracts/oracle/MockV3Aggregator.sol";
import {ProtocolGovernor} from "../../contracts/governance/ProtocolGovernor.sol";
import {ProtocolTimelock} from "../../contracts/governance/ProtocolTimelock.sol";
import {ProtocolTreasury} from "../../contracts/governance/ProtocolTreasury.sol";
import {GovernanceToken} from "../../contracts/token/GovernanceToken.sol";

contract OracleAndGovernanceStubsTest is Test {
    PriceOracle internal oracle;

    address internal eth = makeAddr("eth");
    address internal btc = makeAddr("btc");
    address internal voter = makeAddr("voter");
    address internal module = makeAddr("module");

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

    function testChainlinkAdapterReturnsFreshPrice() public {
        MockV3Aggregator aggregator = new MockV3Aggregator(8, 2_000e8);
        ChainlinkPriceFeed feed = new ChainlinkPriceFeed(address(aggregator), 1 hours);

        assertEq(feed.latestAnswer(), 2_000e8);
        assertEq(feed.decimals(), 8);
    }

    function testChainlinkAdapterRevertsOnStalePrice() public {
        vm.warp(10 days);
        MockV3Aggregator aggregator = new MockV3Aggregator(8, 2_000e8);
        ChainlinkPriceFeed feed = new ChainlinkPriceFeed(address(aggregator), 1 hours);

        aggregator.updateRoundData(2, 2_000e8, block.timestamp - 2 hours, block.timestamp - 2 hours);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkPriceFeed.StalePrice.selector, block.timestamp - 2 hours, 1 hours)
        );
        feed.latestAnswer();
    }

    function testChainlinkAdapterRevertsOnInvalidPrice() public {
        MockV3Aggregator aggregator = new MockV3Aggregator(8, 2_000e8);
        ChainlinkPriceFeed feed = new ChainlinkPriceFeed(address(aggregator), 1 hours);

        aggregator.updateAnswer(0);

        vm.expectRevert(ChainlinkPriceFeed.InvalidPrice.selector);
        feed.latestAnswer();
    }

    function testGovernorName() public {
        GovernanceToken token = new GovernanceToken(address(this));
        ProtocolTimelock timelock = _deployTimelock();
        ProtocolGovernor governor = new ProtocolGovernor(token, timelock);

        assertEq(governor.name(), "DeFiHub Governor");
    }

    function testTimelockMinDelay() public {
        ProtocolTimelock timelock = _deployTimelock();
        assertEq(timelock.getMinDelay(), 2 days);
    }

    function testGovernorParametersMatchSpec() public {
        GovernanceToken token = new GovernanceToken(address(this));
        ProtocolTimelock timelock = _deployTimelock();
        ProtocolGovernor governor = new ProtocolGovernor(token, timelock);

        token.mint(voter, 1_000 ether);
        vm.roll(block.number + 1);

        assertEq(governor.votingDelay(), 7_200);
        assertEq(governor.votingPeriod(), 50_400);
        assertEq(governor.quorumNumerator(), 4);
        assertEq(governor.proposalThreshold(), 10 ether);
    }

    function testProposeVoteQueueExecuteRegistersTreasuryModule() public {
        GovernanceToken token = new GovernanceToken(address(this));
        ProtocolTimelock timelock = _deployTimelock();
        ProtocolGovernor governor = new ProtocolGovernor(token, timelock);
        ProtocolTreasury treasury = new ProtocolTreasury(address(timelock));

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));

        token.mint(voter, 1_000 ether);
        vm.prank(voter);
        token.delegate(voter);
        vm.roll(block.number + 1);

        address[] memory targets = new address[](1);
        targets[0] = address(treasury);

        uint256[] memory values = new uint256[](1);

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeCall(ProtocolTreasury.registerModule, (ProtocolTreasury.Module.AMM, module));

        string memory description = "Register AMM module";

        vm.prank(voter);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + governor.votingDelay() + 1);
        assertEq(uint8(governor.state(proposalId)), 1); // Active

        vm.prank(voter);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + governor.votingPeriod() + 1);
        assertEq(uint8(governor.state(proposalId)), 4); // Succeeded

        bytes32 descriptionHash = keccak256(bytes(description));
        governor.queue(targets, values, calldatas, descriptionHash);
        assertEq(uint8(governor.state(proposalId)), 5); // Queued

        vm.warp(block.timestamp + timelock.getMinDelay() + 1);
        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(uint8(governor.state(proposalId)), 7); // Executed
        assertEq(treasury.moduleAddress(ProtocolTreasury.Module.AMM), module);
    }

    function _deployTimelock() internal returns (ProtocolTimelock) {
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);

        return new ProtocolTimelock(2 days, proposers, executors, address(this));
    }
}
