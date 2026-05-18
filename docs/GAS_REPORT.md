# Gas Optimization Report

## Summary

Gas measurements are based on Foundry test output and Arbitrum Sepolia deployment estimates. Values should be regenerated on the final commit before submission.

## Before / After Optimizations

| Area | Before | After | Result |
|---|---|---|---|
| Math helper | Pure Solidity max comparison | Inline Yul `maxYul` | Test benchmark shows lower gas for Yul path |
| ERC-4626 vault | Standard share math only | OpenZeppelin ERC4626 with decimals offset | Safer rounding behavior and inflation-attack mitigation |
| Oracle use | Direct mock latest answer | Chainlink adapter with stale validation | Slight extra gas, stronger safety |
| Governance execution | Direct owner changes | Governor + Timelock | Higher execution gas, required governance safety |

## Yul Benchmark

From `AdvancedSolidityRequirements.t.sol`:

| Function | Gas |
|---|---:|
| `maxSolidity` | 1554 |
| `maxYul` | 1529 |

## L1 vs L2 Gas Comparison

Arbitrum Sepolia deployment estimate:

| Metric | Value |
|---|---:|
| Estimated gas used by deployment script | 18,223,810 |
| Estimated gas price | 0.040000001 gwei |
| Estimated ETH required | 0.00072895241822381 ETH |

Representative operations:

| Operation | L1 Estimated Gas | Arbitrum Sepolia Gas | Notes |
|---|---:|---:|---|
| Deploy protocol bundle | 18,223,810 | 18,223,810 | Same execution gas, lower L2 fee market cost |
| Add liquidity | 91,250 | 91,250 | From AMM unit test |
| Swap A -> B | 79,860 | 79,860 | From AMM unit test |
| Vault deposit | 88,518 | 88,518 | From ERC4626 unit test |
| Borrow | 188,010 | 188,010 | Deposit + borrow path from lending test |
| Governance lifecycle | 12,255,723 | 12,255,723 | Full propose/vote/queue/execute test |

Execution gas is comparable across EVM chains, but L2 transaction cost is much lower because calldata/execution pricing differs. Final report should include block explorer transaction fees from deployed Arbitrum Sepolia transactions and, if required, a Sepolia L1 dry-run estimate for each operation.

## Regeneration Commands

```bash
forge test --gas-report
forge snapshot
forge script script/Deploy.s.sol --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL"
```

## Optimization Notes

- AMM uses immutable token addresses and LP token address.
- Lending pool uses immutable asset/feed addresses.
- ERC20 interactions use `SafeERC20`.
- Reentrancy-sensitive flows use `ReentrancyGuard`.
- The project intentionally keeps some view helpers readable instead of micro-optimizing every hash operation.
