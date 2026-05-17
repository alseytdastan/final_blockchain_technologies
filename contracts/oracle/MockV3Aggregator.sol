// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockV3Aggregator {
    uint8 public immutable decimals;
    int256 public latestAnswer;
    uint80 public latestRound;
    uint256 public latestStartedAt;
    uint256 public latestUpdatedAt;

    constructor(uint8 decimals_, int256 initialAnswer) {
        decimals = decimals_;
        _updateRoundData(1, initialAnswer, block.timestamp, block.timestamp);
    }

    function updateAnswer(int256 answer) external {
        _updateRoundData(latestRound + 1, answer, block.timestamp, block.timestamp);
    }

    function updateRoundData(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt) external {
        _updateRoundData(roundId, answer, startedAt, updatedAt);
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (latestRound, latestAnswer, latestStartedAt, latestUpdatedAt, latestRound);
    }

    function _updateRoundData(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt) internal {
        latestRound = roundId;
        latestAnswer = answer;
        latestStartedAt = startedAt;
        latestUpdatedAt = updatedAt;
    }
}
