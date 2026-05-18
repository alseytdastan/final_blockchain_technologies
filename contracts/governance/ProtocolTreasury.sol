// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title ProtocolTreasury
/// @notice First-step registry for Option A module addresses.
contract ProtocolTreasury is Ownable {
    error NotOwner();
    error ZeroAddress();
    error ModuleAlreadySet(Module module);

    enum Module {
        AMM,
        Lending,
        Vault4626,
        OracleAdapter,
        Governance,
        Treasury
    }

    mapping(Module => address) public moduleAddress;

    event ModuleRegistered(Module indexed module, address indexed moduleAddress);

    constructor(address initialOwner) Ownable(initialOwner) {
        if (initialOwner == address(0)) revert ZeroAddress();
    }

    function registerModule(Module module, address moduleAddr) external {
        if (msg.sender != owner()) revert NotOwner();
        if (moduleAddr == address(0)) revert ZeroAddress();
        if (moduleAddress[module] != address(0)) revert ModuleAlreadySet(module);

        moduleAddress[module] = moduleAddr;
        emit ModuleRegistered(module, moduleAddr);
    }
}
