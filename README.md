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

## L2 testnet deployment

**Primary network:** Arbitrum Sepolia (chain id `421614`) — matches `frontend/app.js`.  
Course also allows Base Sepolia, Optimism Sepolia, zkSync Sepolia.

### What you need (one-time setup)

| Item | Where to get it |
|------|-----------------|
| Testnet ETH on **Arbitrum Sepolia** | [Alchemy Arbitrum Sepolia faucet](https://www.alchemy.com/faucets/arbitrum-sepolia) or [Chainlink faucet](https://faucets.chain.link/arbitrum-sepolia) |
| `PRIVATE_KEY` | Same account as MetaMask (must have ETH on **Arbitrum Sepolia**, not only other networks) |
| `ARBITRUM_SEPOLIA_RPC_URL` | `https://sepolia-rollup.arbitrum.io/rpc` or Alchemy/Infura |
| `ETHERSCAN_API_KEY` | Free key at [etherscan.io/myapikey](https://etherscan.io/myapikey) (verifies on Arbiscan) |

Copy `.env.example` → `.env` and fill values. **Never commit `.env`.**

### Deploy and verify (Arbitrum Sepolia)

```bash
chmod +x scripts/deploy-arbitrum-sepolia.sh
./scripts/deploy-arbitrum-sepolia.sh
```

Or manually:

```bash
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url arbitrum_sepolia --broadcast --verify -vvvv
DEPLOYMENT_JSON=deployments/arbitrum-sepolia.json \
  forge script script/VerifyDeployment.s.sol:VerifyDeployment --rpc-url arbitrum_sepolia -vvv \
  | tee deployments/verification-arbitrum-sepolia.txt
```

After deploy, addresses are saved to `deployments/arbitrum-sepolia.json`. Update the table below and `frontend/app.js` (`CONFIG`).

### Base Sepolia (optional)

```bash
./scripts/deploy-base-sepolia.sh
```

Requires `BASE_SEPOLIA_RPC_URL` and `BASESCAN_API_KEY` in `.env`.

### Deployed contracts (Arbitrum Sepolia)

| Contract | Address | Explorer |
|----------|---------|----------|
| Mock USDC (`tokenA`) | `0xEc0Cf7f5559431a1E757419804aD800Cb6d01ab9` | [Arbiscan](https://sepolia.arbiscan.io/address/0xEc0Cf7f5559431a1E757419804aD800Cb6d01ab9) |
| Mock WETH (`tokenB`) | `0x05aa36A6F5cCD450ae590b6780507975f8BdA0a9` | [Arbiscan](https://sepolia.arbiscan.io/address/0x05aa36A6F5cCD450ae590b6780507975f8BdA0a9) |
| GovernanceToken (`DFH`) | `0xd128e7BdDa0a96AF805839FaD4D5A22365Aea84b` | [Arbiscan](https://sepolia.arbiscan.io/address/0xd128e7BdDa0a96AF805839FaD4D5A22365Aea84b) |
| AMMPool | `0x27a14e9c611080B52eaC4Bf59cBeD93d15978719` | [Arbiscan](https://sepolia.arbiscan.io/address/0x27a14e9c611080B52eaC4Bf59cBeD93d15978719) |
| YieldVault | `0x280E3BcF84299D8f53eB7876a4daA2bAe9d40124` | [Arbiscan](https://sepolia.arbiscan.io/address/0x280E3BcF84299D8f53eB7876a4daA2bAe9d40124) |
| LendingPool | `0xC409d806B5B5d77d208b7538984DbE15325Dd59b` | [Arbiscan](https://sepolia.arbiscan.io/address/0xC409d806B5B5d77d208b7538984DbE15325Dd59b) |
| ChainlinkPriceFeed adapter | `0x0e7Db0BD600bB8A3919302410F55ACA81B15632B` | [Arbiscan](https://sepolia.arbiscan.io/address/0x0e7Db0BD600bB8A3919302410F55ACA81B15632B) |
| ProtocolGovernor | `0x930568ABa3Ac134bed2FDE34B162E60dBB09b136` | [Arbiscan](https://sepolia.arbiscan.io/address/0x930568ABa3Ac134bed2FDE34B162E60dBB09b136) |
| ProtocolTimelock | `0x8E7354Cf8C131De13255F7ba3e4be253fc6308CF` | [Arbiscan](https://sepolia.arbiscan.io/address/0x8E7354Cf8C131De13255F7ba3e4be253fc6308CF) |
| ProtocolTreasury | `0xB3eAf4CafF78809805642337100d1b1a5A4B6AC7` | [Arbiscan](https://sepolia.arbiscan.io/address/0xB3eAf4CafF78809805642337100d1b1a5A4B6AC7) |
| ProtocolAccessNFT | `0x49b4d149473ca5e2CFb1B02584EAeD6C030eF6B4` | [Arbiscan](https://sepolia.arbiscan.io/address/0x49b4d149473ca5e2CFb1B02584EAeD6C030eF6B4) |
| PoolFactory | `0x7612529B986E33e033C23016feEB6D29d27a6d26` | [Arbiscan](https://sepolia.arbiscan.io/address/0x7612529B986E33e033C23016feEB6D29d27a6d26) |
| UUPS config proxy | `0x3907a81b9BA32855B48010087f68C70dbdCAE24C` | [Arbiscan](https://sepolia.arbiscan.io/address/0x3907a81b9BA32855B48010087f68C70dbdCAE24C) |

Post-deploy check output: [`deployments/verification-arbitrum-sepolia.txt`](deployments/verification-arbitrum-sepolia.txt)

Subgraph deployment instructions and required query checks are in [`docs/SUBGRAPH_DEPLOYMENT.md`](docs/SUBGRAPH_DEPLOYMENT.md).

## Course approval

- **Scenario:** Option A — DeFi Super-App
- **Status:** Scenario selected; Arbitrum Sepolia deployment artifact included

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
* HTML/CSS/JavaScript frontend
* Ethers.js
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
