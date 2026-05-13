# Blockchain Technologies 2 — Final Project

Foundry-based starter for `Option A: DeFi Super-App`:
- AMM
- Lending protocol
- ERC-4626 yield vault
- Chainlink pricing
- DAO governance
- L2 deployment

## First Task Completed

This repository is initialized with Foundry and includes the first project artifact:
- `ProtocolBootstrap` contract to register core module addresses
- test suite for ownership and safety checks
- clean base structure for incremental implementation

## Quick Start

```bash
forge build
forge test
```

## Current Structure

- `src/` smart contracts
- `test/` Foundry tests
- `script/` deployment and scripting files
- `.github/workflows/` CI pipeline

## Next Step (Task 2)

Implement governance token stack (`ERC20Votes + ERC20Permit`) and initial DAO wiring.
