// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ChainlinkPriceFeed} from "../../contracts/oracle/ChainlinkPriceFeed.sol";
import {MockV3Aggregator} from "../../contracts/oracle/MockV3Aggregator.sol";

contract IncompleteRoundAggregator {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, 2_000e8, block.timestamp, block.timestamp, 0);
    }
}

contract ZeroUpdatedAtAggregator {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, 2_000e8, block.timestamp, 0, 1);
    }
}

contract ChainlinkPriceFeedTest is Test {
    function testRevertInvalidAggregator() public {
        vm.expectRevert(ChainlinkPriceFeed.InvalidAggregator.selector);
        new ChainlinkPriceFeed(address(0), 1 hours);
    }

    function testLatestRoundDataReturnsValidatedValues() public {
        MockV3Aggregator aggregator = new MockV3Aggregator(8, 3_000e8);
        ChainlinkPriceFeed feed = new ChainlinkPriceFeed(address(aggregator), 1 hours);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.latestRoundData();

        assertEq(roundId, 1);
        assertEq(answer, 3_000e8);
        assertGt(startedAt, 0);
        assertGt(updatedAt, 0);
        assertEq(answeredInRound, 1);
    }

    function testRevertIncompleteRoundWhenAnsweredInRoundZero() public {
        ChainlinkPriceFeed feed = new ChainlinkPriceFeed(address(new IncompleteRoundAggregator()), 1 hours);

        vm.expectRevert(ChainlinkPriceFeed.IncompleteRound.selector);
        feed.latestAnswer();
    }

    function testRevertIncompleteRoundWhenUpdatedAtZero() public {
        ChainlinkPriceFeed feed = new ChainlinkPriceFeed(address(new ZeroUpdatedAtAggregator()), 1 hours);

        vm.expectRevert(ChainlinkPriceFeed.IncompleteRound.selector);
        feed.latestRoundData();
    }

    function testStaleCheckDisabledWhenMaxStalenessZero() public {
        vm.warp(30 days);
        MockV3Aggregator aggregator = new MockV3Aggregator(8, 2_000e8);
        aggregator.updateRoundData(2, 2_000e8, block.timestamp - 10 days, block.timestamp - 10 days);

        ChainlinkPriceFeed feed = new ChainlinkPriceFeed(address(aggregator), 0);

        assertEq(feed.latestAnswer(), 2_000e8);
    }

    function testRevertNegativePrice() public {
        MockV3Aggregator aggregator = new MockV3Aggregator(8, 2_000e8);
        ChainlinkPriceFeed feed = new ChainlinkPriceFeed(address(aggregator), 1 hours);

        aggregator.updateAnswer(-1);

        vm.expectRevert(ChainlinkPriceFeed.InvalidPrice.selector);
        feed.latestRoundData();
    }
}
