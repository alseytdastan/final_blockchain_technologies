// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MathUtils {
    function maxSolidity(uint256 a, uint256 b) external pure returns (uint256) {
        return a >= b ? a : b;
    }

    function maxYul(uint256 a, uint256 b) external pure returns (uint256 maxValue) {
        assembly {
            maxValue := a
            if gt(b, a) { maxValue := b }
        }
    }
}
