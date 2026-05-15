// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UpgradeableProtocolConfig} from "./UpgradeableProtocolConfig.sol";

contract UpgradeableProtocolConfigV2 is UpgradeableProtocolConfig {
    uint256 public maxLtvBps;

    function setMaxLtvBps(uint256 newMaxLtvBps) external onlyOwner {
        maxLtvBps = newMaxLtvBps;
    }

    function version() external pure returns (string memory) {
        return "V2";
    }
}
