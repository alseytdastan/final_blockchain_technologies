# Coverage Report

Measured with:

```bash
.\.tools\foundry\forge.exe coverage --report summary
```

Run date: 2026-05-17
Foundry: `forge 1.6.0-nightly`

## Summary

| Scope | % Lines | Lines Covered | Requirement |
|---|---:|---:|---:|
| `contracts/` | 97.17% | 240 / 247 | >= 90% |
| Full Foundry summary | 96.88% | 311 / 321 | >= 90% |

## Contract Coverage

| File | % Lines | % Statements | % Branches | % Funcs |
|---|---:|---:|---:|---:|
| `contracts/amm/AMMPool.sol` | 97.56% (80/82) | 91.26% (94/103) | 62.50% (15/24) | 100.00% (12/12) |
| `contracts/amm/PoolFactory.sol` | 100.00% (11/11) | 100.00% (11/11) | 100.00% (0/0) | 100.00% (3/3) |
| `contracts/governance/ProtocolTimelock.sol` | 100.00% (2/2) | 100.00% (1/1) | 100.00% (0/0) | 100.00% (1/1) |
| `contracts/governance/ProtocolTreasury.sol` | 100.00% (9/9) | 90.91% (10/11) | 75.00% (3/4) | 100.00% (2/2) |
| `contracts/lending/LendingPool.sol` | 96.91% (94/97) | 88.46% (115/130) | 38.89% (7/18) | 100.00% (14/14) |
| `contracts/mocks/MockERC20.sol` | 100.00% (2/2) | 100.00% (1/1) | 100.00% (0/0) | 100.00% (1/1) |
| `contracts/oracle/MockV3Aggregator.sol` | 100.00% (5/5) | 100.00% (3/3) | 100.00% (0/0) | 100.00% (2/2) |
| `contracts/oracle/PriceOracle.sol` | 100.00% (3/3) | 100.00% (2/2) | 100.00% (0/0) | 100.00% (1/1) |
| `contracts/token/GovernanceToken.sol` | 100.00% (6/6) | 100.00% (4/4) | 100.00% (0/0) | 100.00% (3/3) |
| `contracts/token/LPToken.sol` | 100.00% (12/12) | 100.00% (9/9) | 100.00% (4/4) | 100.00% (3/3) |
| `contracts/upgradeable/UpgradeableProtocolConfig.sol` | 71.43% (5/7) | 75.00% (3/4) | 100.00% (0/0) | 66.67% (2/3) |
| `contracts/upgradeable/UpgradeableProtocolConfigV2.sol` | 100.00% (4/4) | 100.00% (2/2) | 100.00% (0/0) | 100.00% (2/2) |
| `contracts/utils/MathUtils.sol` | 100.00% (5/5) | 100.00% (5/5) | 100.00% (1/1) | 100.00% (2/2) |
| `contracts/vault/YieldVault.sol` | 100.00% (2/2) | 100.00% (1/1) | 100.00% (0/0) | 100.00% (1/1) |

## Test Run

```text
Ran 17 test suites in 150.37s (482.21s CPU time): 82 tests passed, 0 failed, 0 skipped (82 total tests)
```

Fork tests interacted with mainnet USDC, Uniswap V2 Router, and Chainlink ETH/USD feed during the measured run.
