# Security Audit Report

## Executive Summary

This internal audit reviews the DeFiHub Option A protocol: AMM, lending pool, ERC-4626 vault, governance, timelock, oracle adapter, upgradeable config, ERC-721 badge, deployment scripts, and subgraph/frontend integration.

No Critical, High, or Medium issues are currently known from manual review. Slither output is attached in `docs/slither-output.txt` and the CI job fails on Medium-or-higher findings.

## Scope

Repository: `https://github.com/alseytdastan/final_blockchain_technologies`

Audit base commit: `6c1c947154c2756fcf86fd198437c868bafd1ffb`

In scope:

- `contracts/amm/AMMPool.sol`
- `contracts/amm/PoolFactory.sol`
- `contracts/governance/ProtocolGovernor.sol`
- `contracts/governance/ProtocolTimelock.sol`
- `contracts/governance/ProtocolTreasury.sol`
- `contracts/interfaces/IPriceFeed.sol`
- `contracts/lending/LendingPool.sol`
- `contracts/oracle/ChainlinkPriceFeed.sol`
- `contracts/oracle/PriceOracle.sol`
- `contracts/token/GovernanceToken.sol`
- `contracts/token/LPToken.sol`
- `contracts/token/ProtocolAccessNFT.sol`
- `contracts/upgradeable/UpgradeableProtocolConfig.sol`
- `contracts/upgradeable/UpgradeableProtocolConfigV2.sol`
- `contracts/utils/MathUtils.sol`
- `contracts/vault/YieldVault.sol`
- `script/Deploy.s.sol`
- `script/VerifyDeployment.s.sol`
- `script/UpgradeConfig.s.sol`

Out of scope:

- OpenZeppelin library internals
- Chainlink production aggregator internals
- `contracts/mocks/MockERC20.sol`
- `contracts/oracle/MockV3Aggregator.sol`
- `test/` vulnerability harnesses and test-only helper contracts
- `frontend/` browser UI implementation, except for configuration and security-relevant integration notes
- `subgraph/` indexing infrastructure, except for entity/query completeness and deployed-address consistency
- The Graph hosted infrastructure
- Browser wallet implementation

## Methodology

- Manual review of access control, external calls, oracle validation, governance lifecycle, and upgrade path.
- Foundry unit, fuzz, invariant, and fork tests.
- Vulnerability case study tests for reentrancy and access control.
- Coverage review with `forge coverage`.
- Slither static analysis with `--fail-medium`.

## Findings Table

| ID | Severity | Title | Status |
|---|---|---|---|
| S-01 | Low | Frontend subgraph URL remains a placeholder until The Graph Studio deployment | Fixed |
| S-02 | Informational | Testnet mock oracle is not a production Chainlink feed | Acknowledged |
| S-03 | Gas | CREATE2 address prediction hashes dynamic bytecode in Solidity | Acknowledged |
| S-04 | Informational | Some immutable names do not follow forge lint SCREAMING_SNAKE_CASE style | Acknowledged |
| S-05 | Low | Slither timestamp warnings are protocol deadline, interest accrual, and stale oracle checks | Acknowledged |
| S-06 | Optimization | Lending pool risk parameters could be immutable | Acknowledged |
| S-07 | Medium | AMM liquidity removal updated reserves after LP burn | Fixed |
| S-08 | Medium | Lending strict-equality patterns reported by Slither | Fixed |
| S-09 | Low | Oracle round validation did not check full Chainlink round metadata | Fixed |

## Finding Details

### S-01: Frontend Subgraph URL Placeholder

Severity: Low  
Location: `frontend/app.js`

Description: Contract addresses are configured for Arbitrum Sepolia, but `subgraphUrl` requires the final The Graph Studio deployment URL.

Impact: The subgraph section will not load indexed data until the URL is replaced.

Fix: The subgraph was deployed in The Graph Studio and `frontend/app.js` was updated with the live Studio query URL.

Status: Fixed.

### S-02: Testnet Mock Oracle

Severity: Informational  
Location: `script/Deploy.s.sol`

Description: The deployment script uses `MockV3Aggregator` for testnet demonstration.

Impact: This is acceptable for testnet but not mainnet production.

Fix / mitigation: The mock is explicitly limited to testnet deployments. `Deploy.s.sol` supports using a real feed address through configuration, and `ChainlinkPriceFeed` performs stale, invalid, and incomplete-round checks regardless of whether the upstream feed is a mock or production Chainlink aggregator.

Status: Acknowledged.

### S-03: CREATE2 Hashing Gas

Severity: Gas  
Location: `contracts/amm/PoolFactory.sol`

Description: `predictDeterministicAddress` uses high-level `keccak256(abi.encodePacked(...))`.

Impact: Minor gas cost in a view function.

Fix / mitigation: No security fix required. The function is a view helper used for deterministic address prediction; readability was preferred over a small hashing optimization.

Status: Acknowledged.

### S-04: Forge Lint Naming Notes

Severity: Informational  
Location: multiple contracts

Description: Forge lint suggests uppercase names for some constants/immutables.

Impact: No runtime security impact.

Fix / mitigation: No security fix required. The current public names preserve ERC-style metadata compatibility such as `name`, `symbol`, and `decimals`.

Status: Acknowledged.

### S-05: Slither Timestamp Warnings

Severity: Low  
Location: `contracts/amm/AMMPool.sol`, `contracts/lending/LendingPool.sol`, `contracts/oracle/ChainlinkPriceFeed.sol`

Description: Slither reports timestamp comparisons for swap deadlines, linear interest accrual, health checks, and oracle staleness checks.

Impact: These uses are not randomness sources. They are bounded time checks required by the assignment and by normal DeFi UX.

Fix / mitigation: No code change required. `block.timestamp` is used only for user-provided swap deadlines, deterministic interest accrual windows, and oracle staleness validation. It is not used for randomness.

Status: Acknowledged.

### S-06: Lending Pool Risk Parameters Could Be Immutable

Severity: Optimization  
Location: `contracts/lending/LendingPool.sol`

Description: Slither reports `maxLtvBps`, `liquidationThresholdBps`, `borrowRateBpsPerYear`, and `liquidationBonusBps` as candidates for `immutable`.

Impact: Keeping them as storage values costs slightly more gas but preserves the protocol design option for future DAO-governed parameter updates.

Fix / mitigation: No security fix required. The storage layout intentionally leaves room for future Timelock-governed parameter updates.

Status: Acknowledged.

### S-07: AMM Liquidity Removal Reserve Update Order

Severity: Medium  
Location: `contracts/amm/AMMPool.sol`

Description: Earlier versions burned LP tokens before updating `reserveA` and `reserveB` in `removeLiquidity`. Slither reported this as a cross-function reentrancy risk because an external token call happened before all AMM accounting effects were applied.

Impact: The pool uses `nonReentrant`, so the practical exploit path was limited, but the function did not fully follow Checks-Effects-Interactions.

Fix: `removeLiquidity` now updates `reserveA` and `reserveB` before calling `lpToken.burn(...)`, then transfers underlying assets out. This aligns the function with CEI and removes the Medium Slither finding.

Status: Fixed.

### S-08: Lending Strict Equality Patterns

Severity: Medium  
Location: `contracts/lending/LendingPool.sol`

Description: Slither reported strict equality checks such as `debt == 0`, `elapsed == 0`, and `principal == 0` in lending accounting paths.

Impact: The comparisons were not directly exploitable because they checked exact zero sentinel values, but Slither classifies strict equality as Medium risk in financial code where precision and edge cases matter.

Fix: The checks were rewritten to equivalent threshold comparisons such as `< 1`. This keeps behavior unchanged for integer token accounting while removing the Medium Slither findings.

Status: Fixed.

### S-09: Oracle Round Metadata Validation

Severity: Low  
Location: `contracts/oracle/ChainlinkPriceFeed.sol`

Description: Earlier oracle validation checked price positivity and stale timestamps but did not validate all Chainlink round metadata returned by `latestRoundData`.

Impact: Incomplete or inconsistent rounds could be accepted if only partial metadata was checked.

Fix: `ChainlinkPriceFeed` now implements the Chainlink-style interface and validates `roundId`, `startedAt`, `updatedAt`, and `answeredInRound`. It reverts on invalid price, incomplete rounds, and stale price data.

Status: Fixed.

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

Final Slither output is attached in `docs/slither-output.txt`. It was generated with:

```bash
VIRTUAL_ENV="$PWD/.venv" slither . --filter-paths "lib|test|script"
```

Summary: zero High findings and zero Medium findings. Remaining findings are Low timestamp warnings, Informational assembly / literal formatting notes, and Optimization notes listed above.
