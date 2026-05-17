// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";

/// @title ProtocolTimelock
/// @notice DAO execution delay controller. It should own treasury/admin roles after bootstrap.
contract ProtocolTimelock is TimelockController {
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin)
        TimelockController(minDelay, proposers, executors, admin)
    {}
}
