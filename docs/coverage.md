# Test Coverage Report

Generated with `forge coverage` (optimizer disabled for accuracy).

## Summary

| Metric | Coverage |
|--------|----------|
| **Lines** | **97.89%** (372 / 380) |
| Statements | 96.69% (409 / 423) |
| Branches | 82.54% (52 / 63) |
| Functions | 96.43% (81 / 84) |

## Test suite

- **113** tests (unit, fuzz, invariant, fork)
- All passing in CI

## Contract highlights (`contracts/`)

| Contract | Line coverage |
|----------|---------------|
| AMMPool | 97.56%+ |
| LendingPool | 96.91%+ |
| YieldVault | 100% |
| ChainlinkPriceFeed | 100% |
| ProtocolGovernor | 95.45% |
| UpgradeableProtocolConfig | 100% |
| PoolFactory | 100% |

Scripts under `script/` are excluded via `no_match_coverage` in `foundry.toml` (deployment scripts are not part of on-chain logic).

## Regenerate

```bash
forge coverage
```
