// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPriceFeed} from "../interfaces/IPriceFeed.sol";

interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/// @title ChainlinkPriceFeed
/// @notice Thin oracle adapter that rejects invalid, incomplete, or stale Chainlink rounds.
contract ChainlinkPriceFeed is IPriceFeed, IChainlinkAggregatorV3 {
    IChainlinkAggregatorV3 public immutable aggregator;
    uint256 public immutable maxStaleness;

    error InvalidAggregator();
    error InvalidPrice();
    error IncompleteRound();
    error StalePrice(uint256 updatedAt, uint256 maxStaleness);

    constructor(address aggregator_, uint256 maxStaleness_) {
        if (aggregator_ == address(0)) revert InvalidAggregator();
        aggregator = IChainlinkAggregatorV3(aggregator_);
        maxStaleness = maxStaleness_;
    }

    function latestAnswer() external view override returns (int256) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            aggregator.latestRoundData();
        _validate(roundId, answer, startedAt, updatedAt, answeredInRound);
        return answer;
    }

    function decimals() external view override(IPriceFeed, IChainlinkAggregatorV3) returns (uint8) {
        return aggregator.decimals();
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = aggregator.latestRoundData();
        _validate(roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    function _validate(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
        internal
        view
    {
        if (answer <= 0) revert InvalidPrice();
        if (roundId == 0 || startedAt == 0 || updatedAt == 0 || answeredInRound < roundId) revert IncompleteRound();
        if (maxStaleness != 0 && block.timestamp - updatedAt > maxStaleness) {
            revert StalePrice(updatedAt, maxStaleness);
        }
    }
}
