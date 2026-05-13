// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ProtocolConfigV1} from "./ProtocolConfigV1.sol";

contract ProtocolConfigV2 is ProtocolConfigV1 {
    uint256 public maxLtvBps;

    function setMaxLtvBps(uint256 newMaxLtvBps) external onlyOwner {
        maxLtvBps = newMaxLtvBps;
    }

    function version() external pure returns (string memory) {
        return "V2";
    }
}
