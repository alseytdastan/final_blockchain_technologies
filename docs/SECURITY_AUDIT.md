# Security Audit Report

## Executive Summary

This internal audit reviews the DeFiHub Option A protocol: AMM, lending pool, ERC-4626 vault, governance, timelock, oracle adapter, upgradeable config, ERC-721 badge, deployment scripts, and subgraph/frontend integration.

No Critical, High, or Medium issues are currently known from manual review. Slither must still be executed in CI and its final output attached before submission.

## Scope

Commit: final submission commit to be filled after final commit.

In scope:

- `contracts/amm/AMMPool.sol`
- `contracts/amm/PoolFactory.sol`
- `contracts/lending/LendingPool.sol`
- `contracts/vault/YieldVault.sol`
- `contracts/oracle/ChainlinkPriceFeed.sol`
- `contracts/token/GovernanceToken.sol`
- `contracts/token/ProtocolAccessNFT.sol`
- `contracts/governance/*`
- `contracts/upgradeable/*`
- `script/Deploy.s.sol`
- `script/VerifyDeployment.s.sol`
- `script/UpgradeConfig.s.sol`

Out of scope:

- OpenZeppelin library internals
- Chainlink production aggregator internals
- The Graph hosted infrastructure
- Browser wallet implementation

## Methodology

- Manual review of access control, external calls, oracle validation, governance lifecycle, and upgrade path.
- Foundry unit, fuzz, invariant, and fork tests.
- Vulnerability case study tests for reentrancy and access control.
- Coverage review with `forge coverage`.
- Slither static analysis required before final submission.

## Findings Table

| ID | Severity | Title | Status |
|---|---|---|---|
| S-01 | Low | Frontend subgraph URL remains a placeholder until The Graph Studio deployment | Acknowledged |
| S-02 | Informational | Testnet mock oracle is not a production Chainlink feed | Acknowledged |
| S-03 | Gas | CREATE2 address prediction hashes dynamic bytecode in Solidity | Acknowledged |
| S-04 | Informational | Some immutable names do not follow forge lint SCREAMING_SNAKE_CASE style | Acknowledged |

## Finding Details

### S-01: Frontend Subgraph URL Placeholder

Severity: Low  
Location: `frontend/app.js`

Description: Contract addresses are configured for Arbitrum Sepolia, but `subgraphUrl` requires the final The Graph Studio deployment URL.

Impact: The subgraph section will not load indexed data until the URL is replaced.

Recommendation: Deploy the subgraph and replace `YOUR_SUBGRAPH_ID`.

Status: Acknowledged.

### S-02: Testnet Mock Oracle

Severity: Informational  
Location: `script/Deploy.s.sol`

Description: The deployment script uses `MockV3Aggregator` for testnet demonstration.

Impact: This is acceptable for testnet but not mainnet production.

Recommendation: Replace with real Chainlink feed addresses for production deployments.

Status: Acknowledged.

### S-03: CREATE2 Hashing Gas

Severity: Gas  
Location: `contracts/amm/PoolFactory.sol`

Description: `predictDeterministicAddress` uses high-level `keccak256(abi.encodePacked(...))`.

Impact: Minor gas cost in a view function.

Recommendation: Keep as-is for readability or optimize with assembly if required.

Status: Acknowledged.

### S-04: Forge Lint Naming Notes

Severity: Informational  
Location: multiple contracts

Description: Forge lint suggests uppercase names for some constants/immutables.

Impact: No runtime security impact.

Recommendation: Rename in a style-only pass if desired.

Status: Acknowledged.

## Centralization Analysis

The Timelock owns privileged contracts after deployment. The deployer no longer has `DEFAULT_ADMIN_ROLE` on the Timelock after bootstrap. Governance token ownership is transferred to the Timelock, so future minting or privileged changes must pass through DAO execution.

If a role-holder is compromised during deployment, initial setup can be subverted. After bootstrap, compromise risk shifts to governance voting power and Timelock proposer/executor roles.

## Governance Attack Analysis

Flash-loan governance attacks: `ERC20Votes` uses historical checkpoints, so voting power must exist at the proposal snapshot. Same-block flash-loan voting is mitigated.

Whale attacks: A whale can influence voting if they hold enough delegated supply. The 4% quorum and 1% proposal threshold raise the cost but do not eliminate token concentration risk.

Proposal spam: The 1% proposal threshold reduces spam by requiring meaningful voting power.

Timelock bypass: Execution goes through `GovernorTimelockControl`; the deployment verification script checks that the deployer no longer has Timelock admin.

## Oracle Attack Analysis

Price manipulation: Lending reads from the Chainlink adapter rather than AMM spot price, reducing local pool manipulation risk.

Stale price: `ChainlinkPriceFeed` reverts if `updatedAt == 0` or if `block.timestamp - updatedAt > maxStaleness`.

Invalid price: The adapter reverts if `answer <= 0`.

Feed depeg / feed failure: The protocol can halt lending price reads if the feed is stale or invalid. Governance should replace feeds through Timelock if a feed becomes unreliable.

## Vulnerability Case Studies

### Reentrancy

Before: `VulnerableEthVault` sends ETH before clearing user balance.  
After: `FixedEthVault` updates balance before the external call and uses a lock.  
Tests: `testCaseStudy_ReentrancyBeforeDrainsVulnerableVault` and `testCaseStudy_ReentrancyAfterBlockedByEffectsBeforeInteractions`.

### Access Control

Before: `VulnerableParameterStore` allows anyone to change fee parameters.  
After: `FixedParameterStore` restricts changes to owner.  
Tests: `testCaseStudy_AccessControlBeforeAllowsUnauthorizedParameterChange` and `testCaseStudy_AccessControlAfterBlocksUnauthorizedParameterChange`.

## Slither Appendix

Final Slither output must be attached after running:

```bash
slither . --filter-paths "lib|test|script"
```

Submission requirement: zero High and zero Medium findings. Low and Informational findings must be listed above or in this appendix.
