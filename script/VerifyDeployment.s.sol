// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ProtocolGovernor} from "../contracts/governance/ProtocolGovernor.sol";
import {ProtocolTimelock} from "../contracts/governance/ProtocolTimelock.sol";
import {ProtocolTreasury} from "../contracts/governance/ProtocolTreasury.sol";
import {YieldVault} from "../contracts/vault/YieldVault.sol";
import {LendingPool} from "../contracts/lending/LendingPool.sol";
import {ProtocolAccessNFT} from "../contracts/token/ProtocolAccessNFT.sol";
import {ChainlinkPriceFeed} from "../contracts/oracle/ChainlinkPriceFeed.sol";

/// @notice Post-deploy checks for course submission. Reads deployment JSON from DEPLOYMENT_JSON or by chain id.
contract VerifyDeployment is Script {
    using stdJson for string;

    uint256 internal constant TWO_DAYS = 2 days;
    uint256 internal constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 internal constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;

    function run() external {
        string memory path = _deploymentJsonPath();
        string memory json = vm.readFile(path);

        address deployer = json.readAddress(".deployer");
        address governanceToken = json.readAddress(".governanceToken");
        address timelockAddr = json.readAddress(".timelock");
        address governorAddr = json.readAddress(".governor");
        address treasuryAddr = json.readAddress(".treasury");
        address pool = json.readAddress(".pool");
        address vaultAddr = json.readAddress(".vault");
        address lendingPoolAddr = json.readAddress(".lendingPool");
        address oracleAddr = json.readAddress(".oracle");
        address badgeAddr = json.readAddress(".badge");

        ProtocolTimelock timelock = ProtocolTimelock(payable(timelockAddr));
        ProtocolGovernor governor = ProtocolGovernor(payable(governorAddr));
        ProtocolTreasury treasury = ProtocolTreasury(treasuryAddr);

        console2.log("=== DeFiHub post-deployment verification ===");
        console2.log("deployment file", path);
        console2.log("chainId", block.chainid);

        _checkEq("GovernanceToken owner is Timelock", Ownable(governanceToken).owner(), timelockAddr);
        _checkEq("YieldVault owner is Timelock", YieldVault(vaultAddr).owner(), timelockAddr);
        _checkEq("LendingPool owner is Timelock", LendingPool(lendingPoolAddr).owner(), timelockAddr);
        _checkEq("ProtocolAccessNFT owner is Timelock", ProtocolAccessNFT(badgeAddr).owner(), timelockAddr);

        _checkEq("Timelock min delay", timelock.getMinDelay(), TWO_DAYS);
        _checkEq("Governor votingDelay", governor.votingDelay(), governor.VOTING_DELAY_BLOCKS());
        _checkEq("Governor votingPeriod", governor.votingPeriod(), governor.VOTING_PERIOD_BLOCKS());
        _checkEq("Governor quorum numerator", governor.quorumNumerator(), governor.QUORUM_PERCENT());

        _checkTrue("Governor has PROPOSER_ROLE on Timelock", timelock.hasRole(timelock.PROPOSER_ROLE(), governorAddr));
        _checkTrue("Governor has CANCELLER_ROLE on Timelock", timelock.hasRole(timelock.CANCELLER_ROLE(), governorAddr));
        _checkFalse(
            "Deployer lacks Timelock DEFAULT_ADMIN_ROLE", timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), deployer)
        );

        _checkEq("Treasury registers AMM", treasury.moduleAddress(ProtocolTreasury.Module.AMM), pool);
        _checkEq("Treasury registers Lending", treasury.moduleAddress(ProtocolTreasury.Module.Lending), lendingPoolAddr);
        _checkEq("Treasury registers Vault", treasury.moduleAddress(ProtocolTreasury.Module.Vault4626), vaultAddr);
        _checkEq("Treasury registers Oracle", treasury.moduleAddress(ProtocolTreasury.Module.OracleAdapter), oracleAddr);
        _checkEq(
            "Treasury registers Governance", treasury.moduleAddress(ProtocolTreasury.Module.Governance), governorAddr
        );

        int256 price = ChainlinkPriceFeed(oracleAddr).latestAnswer();
        _checkTrue("Oracle returns positive price", price > 0);

        console2.log("=== ALL CHECKS PASSED ===");
    }

    function _checkEq(string memory label, uint256 actual, uint256 expected) internal pure {
        require(actual == expected, string.concat(label, " FAILED"));
    }

    function _checkEq(string memory label, address actual, address expected) internal pure {
        require(actual == expected, string.concat(label, " FAILED"));
    }

    function _checkTrue(string memory label, bool condition) internal pure {
        require(condition, string.concat(label, " FAILED"));
    }

    function _checkFalse(string memory label, bool condition) internal pure {
        require(!condition, string.concat(label, " FAILED"));
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
