// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {AMMPool} from "../contracts/amm/AMMPool.sol";
import {ProtocolGovernor} from "../contracts/governance/ProtocolGovernor.sol";
import {ProtocolTimelock} from "../contracts/governance/ProtocolTimelock.sol";
import {ProtocolTreasury} from "../contracts/governance/ProtocolTreasury.sol";
import {YieldVault} from "../contracts/vault/YieldVault.sol";
import {LendingPool} from "../contracts/lending/LendingPool.sol";
import {ProtocolAccessNFT} from "../contracts/token/ProtocolAccessNFT.sol";
import {ChainlinkPriceFeed} from "../contracts/oracle/ChainlinkPriceFeed.sol";

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

        address deployer = json.readAddress(".deployer");
        address tokenA = json.readAddress(".tokenA");
        address tokenB = json.readAddress(".tokenB");
        address governanceToken = json.readAddress(".governanceToken");
        address timelockAddress = json.readAddress(".timelock");
        address governorAddress = json.readAddress(".governor");
        address treasuryAddress = json.readAddress(".treasury");
        address poolAddress = json.readAddress(".pool");
        address vaultAddress = json.readAddress(".vault");
        address lendingPoolAddress = json.readAddress(".lendingPool");
        address badgeAddress = json.readAddress(".badge");
        address configProxyAddress = json.readAddress(".configProxy");

        ProtocolTimelock timelock = ProtocolTimelock(payable(timelockAddress));
        ProtocolGovernor governor = ProtocolGovernor(payable(governorAddress));
        ProtocolTreasury treasury = ProtocolTreasury(treasuryAddress);
        AMMPool pool = AMMPool(poolAddress);

        _requireDeployed(treasuryAddress, "treasury");
        _requireDeployed(governanceToken, "governance token");
        _requireDeployed(vaultAddress, "vault");
        _requireDeployed(lendingPoolAddress, "lending pool");
        _requireDeployed(badgeAddress, "badge");
        _requireDeployed(configProxyAddress, "config proxy");
        _requireDeployed(poolAddress, "AMM pool");
        _requireDeployed(governorAddress, "governor");
        _requireDeployed(timelockAddress, "timelock");

        require(treasury.owner() == timelockAddress, "treasury owner is not timelock");
        require(timelock.getMinDelay() == TWO_DAYS, "timelock delay mismatch");

        require(governor.votingDelay() == 7_200, "governor voting delay mismatch");
        require(governor.votingPeriod() == 50_400, "governor voting period mismatch");
        require(governor.quorumNumerator() == 4, "governor quorum mismatch");
        require(governor.proposalThreshold() == 1_000 ether, "governor threshold mismatch");
        require(governor.timelock() == timelockAddress, "governor timelock mismatch");

        require(timelock.hasRole(timelock.PROPOSER_ROLE(), governorAddress), "governor missing proposer role");
        require(timelock.hasRole(timelock.CANCELLER_ROLE(), governorAddress), "governor missing canceller role");
        require(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)), "executor role is not open");
        require(!timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), deployer), "deployer still has timelock admin");

        require(IOwnable(governanceToken).owner() == timelockAddress, "governance token owner is not timelock");
        require(IOwnable(vaultAddress).owner() == timelockAddress, "vault owner is not timelock");
        require(IOwnable(lendingPoolAddress).owner() == timelockAddress, "lending owner is not timelock");
        require(IOwnable(badgeAddress).owner() == timelockAddress, "badge owner is not timelock");
        require(IOwnable(configProxyAddress).owner() == timelockAddress, "config proxy owner is not timelock");

        require(pool.tokenA() == tokenA, "pool tokenA mismatch");
        require(pool.tokenB() == tokenB, "pool tokenB mismatch");
        require(pool.reserveA() > 0 && pool.reserveB() > 0, "pool has no initial liquidity");

        console2.log("Deployment verification passed");
        console2.log("timelock", timelockAddress);
        console2.log("governor", governorAddress);
        console2.log("treasury", treasuryAddress);
        console2.log("pool", poolAddress);
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
