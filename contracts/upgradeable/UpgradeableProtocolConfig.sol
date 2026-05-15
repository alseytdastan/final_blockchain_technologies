// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract UpgradeableProtocolConfig is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public feeBps;
    string public protocolName;

    function initialize(
        address initialOwner,
        uint256 initialFeeBps,
        string calldata initialName
    ) external initializer {
        __Ownable_init(initialOwner);
        feeBps = initialFeeBps;
        protocolName = initialName;
    }

    function setFeeBps(uint256 newFeeBps) external onlyOwner {
        feeBps = newFeeBps;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
