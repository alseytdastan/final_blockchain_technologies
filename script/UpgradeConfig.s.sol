// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {UpgradeableProtocolConfigV2} from "../contracts/upgradeable/UpgradeableProtocolConfigV2.sol";

interface IUUPSUpgradeable {
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

interface IProtocolConfigV2 {
    function owner() external view returns (address);
    function protocolName() external view returns (string memory);
    function feeBps() external view returns (uint256);
    function maxLtvBps() external view returns (uint256);
    function version() external view returns (string memory);
}

contract UpgradeConfig is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address proxy = vm.envAddress("CONFIG_PROXY");
        uint256 maxLtvBps = vm.envOr("CONFIG_MAX_LTV_BPS", uint256(7_500));

        vm.startBroadcast(deployerKey);

        UpgradeableProtocolConfigV2 implementationV2 = new UpgradeableProtocolConfigV2();
        bytes memory callData = abi.encodeCall(UpgradeableProtocolConfigV2.setMaxLtvBps, (maxLtvBps));
        IUUPSUpgradeable(proxy).upgradeToAndCall(address(implementationV2), callData);

        vm.stopBroadcast();

        IProtocolConfigV2 upgraded = IProtocolConfigV2(proxy);
        require(keccak256(bytes(upgraded.version())) == keccak256(bytes("V2")), "upgrade did not reach V2");
        require(upgraded.maxLtvBps() == maxLtvBps, "max LTV not initialized");

        console2.log("Config proxy upgraded to V2");
        console2.log("proxy", proxy);
        console2.log("implementationV2", address(implementationV2));
        console2.log("owner", upgraded.owner());
        console2.log("protocolName", upgraded.protocolName());
        console2.log("feeBps", upgraded.feeBps());
        console2.log("maxLtvBps", upgraded.maxLtvBps());
    }
}
