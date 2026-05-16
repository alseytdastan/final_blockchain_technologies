# DeFi Super-App — Full-Stack Decentralized Protocol

A production-grade DeFi protocol built for the Blockchain Technologies 2 Final Project.
The platform combines a Constant Product AMM, ERC-4626 Yield Vault, DAO Governance, Chainlink Oracles, and Layer 2 deployment into a single decentralized ecosystem.

## Core Features

* Constant Product AMM (x·y = k) with LP tokens and slippage protection
* ERC-4626 tokenized yield vault
* DAO governance using OpenZeppelin Governor + TimelockController
* ERC20Votes governance token with ERC20Permit
* Chainlink price feed integration with stale price protection
* Upgradeable smart contracts using UUPS proxy pattern
* Factory contracts using CREATE and CREATE2
* The Graph subgraph indexing and GraphQL queries
* Arbitrum / Base / Optimism Sepolia deployment
* Full Foundry test suite:

  * Unit tests
  * Fuzz tests
  * Invariant tests
  * Fork tests
* CI/CD with GitHub Actions, Slither, forge coverage, solhint, and Prettier

## Local development

```bash
forge build
forge test -vv
forge fmt --check
```

## Course approval

- **Scenario:** Option A — DeFi Super-App
- **Status:** Pending instructor approval (update date when confirmed)

## Team roster

| Member | GitHub | Responsibility |
|--------|--------|----------------|
| Dastan | @alseytdastan | AMM, lending, ERC-4626 vault |
| Nursultan | @kimblied | Governance, security, audit |
| Akylbek | @sabyrzzhan | Frontend, subgraph, deploy, CI |

## Tech Stack

* Solidity
* Foundry
* OpenZeppelin
* Chainlink
* The Graph
* React + Wagmi + Viem
* TypeScript
* GitHub Actions

## Security

* Reentrancy protection
* AccessControl role management
* Timelock governance
* Slither static analysis
* Internal security audit report
* Vulnerability reproduction and fixes

## Architecture

The protocol follows modern DeFi engineering standards with modular contracts, upgradeable proxy architecture, DAO-controlled treasury, and Layer 2 optimized deployments.

## Team Goal

To design, implement, audit, and deploy a complete production-style decentralized finance protocol demonstrating advanced smart contract engineering and full-stack Web3 development.

