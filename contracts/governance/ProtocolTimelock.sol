// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ProtocolTimelock {
    uint256 public immutable minDelay;

    constructor(uint256 minDelay_) {
        minDelay = minDelay_;
    }
}
