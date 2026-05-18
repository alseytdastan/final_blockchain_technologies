// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {AMMPool} from "../contracts/amm/AMMPool.sol";
import {ProtocolGovernor} from "../contracts/governance/ProtocolGovernor.sol";
import {ProtocolTimelock} from "../contracts/governance/ProtocolTimelock.sol";
import {ProtocolTreasury} from "../contracts/governance/ProtocolTreasury.sol";

interface IOwnable {
    function owner() external view returns (address);
}

/// @notice Post-deploy checks for course submission. Reads deployment JSON from DEPLOYMENT_JSON or by chain id.
contract VerifyDeployment is Script {
    using stdJson for string;

    uint256 internal constant TWO_DAYS = 2 days;
    uint256 internal constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 internal constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;

    function run() external view {
        string memory path = _deploymentJsonPath();
        string memory json = vm.readFile(path);

        _checkBytecode(json);
        _checkGovernance(json);
        _checkOwnership(json);
        _checkPool(json);

        console2.log("Deployment verification passed");
        console2.log("timelock", json.readAddress(".timelock"));
        console2.log("governor", json.readAddress(".governor"));
        console2.log("treasury", json.readAddress(".treasury"));
        console2.log("pool", json.readAddress(".pool"));
    }

    function _checkBytecode(string memory json) internal view {
        _requireDeployed(json.readAddress(".treasury"), "treasury");
        _requireDeployed(json.readAddress(".governanceToken"), "governance token");
        _requireDeployed(json.readAddress(".vault"), "vault");
        _requireDeployed(json.readAddress(".lendingPool"), "lending pool");
        _requireDeployed(json.readAddress(".badge"), "badge");
        _requireDeployed(json.readAddress(".configProxy"), "config proxy");
        _requireDeployed(json.readAddress(".pool"), "AMM pool");
        _requireDeployed(json.readAddress(".governor"), "governor");
        _requireDeployed(json.readAddress(".timelock"), "timelock");
    }

    function _checkGovernance(string memory json) internal view {
        address timelockAddress = json.readAddress(".timelock");
        address governorAddress = json.readAddress(".governor");
        ProtocolTimelock timelock = ProtocolTimelock(payable(timelockAddress));
        ProtocolGovernor governor = ProtocolGovernor(payable(governorAddress));

        require(timelock.getMinDelay() == TWO_DAYS, "timelock delay mismatch");
        require(governor.votingDelay() == 7_200, "governor voting delay mismatch");
        require(governor.votingPeriod() == 50_400, "governor voting period mismatch");
        require(governor.quorumNumerator() == 4, "governor quorum mismatch");
        require(governor.proposalThreshold() == 1_000 ether, "governor threshold mismatch");
        require(governor.timelock() == timelockAddress, "governor timelock mismatch");

        require(timelock.hasRole(timelock.PROPOSER_ROLE(), governorAddress), "governor missing proposer role");
        require(timelock.hasRole(timelock.CANCELLER_ROLE(), governorAddress), "governor missing canceller role");
        require(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)), "executor role is not open");
        require(
            !timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), json.readAddress(".deployer")),
            "deployer still has timelock admin"
        );
    }

    function _checkOwnership(string memory json) internal view {
        address timelockAddress = json.readAddress(".timelock");

        require(
            ProtocolTreasury(json.readAddress(".treasury")).owner() == timelockAddress, "treasury owner is not timelock"
        );
        require(
            IOwnable(json.readAddress(".governanceToken")).owner() == timelockAddress,
            "governance token owner is not timelock"
        );
        require(IOwnable(json.readAddress(".vault")).owner() == timelockAddress, "vault owner is not timelock");
        require(IOwnable(json.readAddress(".lendingPool")).owner() == timelockAddress, "lending owner is not timelock");
        require(IOwnable(json.readAddress(".badge")).owner() == timelockAddress, "badge owner is not timelock");
        require(
            IOwnable(json.readAddress(".configProxy")).owner() == timelockAddress, "config proxy owner is not timelock"
        );
    }

    function _checkPool(string memory json) internal view {
        AMMPool pool = AMMPool(json.readAddress(".pool"));

        require(pool.tokenA() == json.readAddress(".tokenA"), "pool tokenA mismatch");
        require(pool.tokenB() == json.readAddress(".tokenB"), "pool tokenB mismatch");
        require(pool.reserveA() > 0 && pool.reserveB() > 0, "pool has no initial liquidity");
    }

    function _requireDeployed(address target, string memory label) internal view {
        require(target.code.length > 0, string.concat(label, " address has no bytecode on this network"));
    }

    function _deploymentJsonPath() internal view returns (string memory) {
        try vm.envString("DEPLOYMENT_JSON") returns (string memory path) {
            return path;
        } catch {}

        if (block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID) {
            return "deployments/arbitrum-sepolia.json";
        }

        if (block.chainid == BASE_SEPOLIA_CHAIN_ID) {
            return "deployments/base-sepolia.json";
        }

        return string.concat("deployments/", vm.toString(block.chainid), ".json");
    }
}
