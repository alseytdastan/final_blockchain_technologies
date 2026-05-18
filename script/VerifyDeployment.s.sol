// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";

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
    function run() external view {
        address deployer = vm.envAddress("DEPLOYER");
        address tokenA = vm.envAddress("TOKEN_A");
        address tokenB = vm.envAddress("TOKEN_B");
        address governanceToken = vm.envAddress("GOVERNANCE_TOKEN");
        address timelockAddress = vm.envAddress("TIMELOCK");
        address governorAddress = vm.envAddress("GOVERNOR");
        address treasuryAddress = vm.envAddress("TREASURY");
        address poolAddress = vm.envAddress("POOL");
        address vaultAddress = vm.envAddress("VAULT");
        address lendingPoolAddress = vm.envAddress("LENDING_POOL");
        address badgeAddress = vm.envAddress("BADGE");
        address configProxyAddress = vm.envAddress("CONFIG_PROXY");

        ProtocolTimelock timelock = ProtocolTimelock(payable(timelockAddress));
        ProtocolGovernor governor = ProtocolGovernor(payable(governorAddress));
        ProtocolTreasury treasury = ProtocolTreasury(treasuryAddress);
        AMMPool pool = AMMPool(poolAddress);

        require(treasury.owner() == timelockAddress, "treasury owner is not timelock");
        require(timelock.getMinDelay() == 2 days, "timelock delay mismatch");

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
}
