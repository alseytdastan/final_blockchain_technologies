// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockV3Aggregator {
    uint8 public immutable decimals;
    int256 public latestAnswer;

    constructor(uint8 decimals_, int256 initialAnswer) {
        decimals = decimals_;
        latestAnswer = initialAnswer;
    }

    function updateAnswer(int256 answer) external {
        latestAnswer = answer;
    }
}
