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
| Mock USDC (`tokenA`) | `0x7abAE8a8217f77CA0EDb60bbd00297aD936a392c` | [Arbiscan](https://sepolia.arbiscan.io/address/0x7abAE8a8217f77CA0EDb60bbd00297aD936a392c) |
| Mock WETH (`tokenB`) | `0xF9B62c21F0D9655CaEeC0A21DAeA9409B2678E1A` | [Arbiscan](https://sepolia.arbiscan.io/address/0xF9B62c21F0D9655CaEeC0A21DAeA9409B2678E1A) |
| GovernanceToken (`DFH`) | `0xA0d618c8F07d823416fC98dCC54fc5850Bba3A77` | [Arbiscan](https://sepolia.arbiscan.io/address/0xA0d618c8F07d823416fC98dCC54fc5850Bba3A77) |
| AMMPool | `0x03b1882CE3EB333A29806c66acD24AaeB7F8eC7B` | [Arbiscan](https://sepolia.arbiscan.io/address/0x03b1882CE3EB333A29806c66acD24AaeB7F8eC7B) |
| YieldVault | `0x1F248BF5FFa817d5658253AF86ffCFB8e6710715` | [Arbiscan](https://sepolia.arbiscan.io/address/0x1F248BF5FFa817d5658253AF86ffCFB8e6710715) |
| LendingPool | `0x89e6a15EA06342622b9cff3Ee5F1C1ed9a7102F9` | [Arbiscan](https://sepolia.arbiscan.io/address/0x89e6a15EA06342622b9cff3Ee5F1C1ed9a7102F9) |
| ChainlinkPriceFeed adapter | `0x84e57E4034FBfbbd14Ee7ed7A1DAe797Bdc5c20d` | [Arbiscan](https://sepolia.arbiscan.io/address/0x84e57E4034FBfbbd14Ee7ed7A1DAe797Bdc5c20d) |
| ProtocolGovernor | `0xdA6E681f08045391C9b342349bFd3DC263f2556F` | [Arbiscan](https://sepolia.arbiscan.io/address/0xdA6E681f08045391C9b342349bFd3DC263f2556F) |
| ProtocolTimelock | `0xAeCF1aF0d940cFFf5da14296a010138891e5b1b3` | [Arbiscan](https://sepolia.arbiscan.io/address/0xAeCF1aF0d940cFFf5da14296a010138891e5b1b3) |
| ProtocolTreasury | `0x8991EC3E7C563B7ED2cf32cDE04B604193a53D42` | [Arbiscan](https://sepolia.arbiscan.io/address/0x8991EC3E7C563B7ED2cf32cDE04B604193a53D42) |
| ProtocolAccessNFT | `0x138678BDD4A68d461a91DD67eF9DbDFb0e653d58` | [Arbiscan](https://sepolia.arbiscan.io/address/0x138678BDD4A68d461a91DD67eF9DbDFb0e653d58) |
| PoolFactory | `0xd51207288c2B803A3d365a04Bb7C316072a4a3FA` | [Arbiscan](https://sepolia.arbiscan.io/address/0xd51207288c2B803A3d365a04Bb7C316072a4a3FA) |
| UUPS config proxy | `0xC7e28c8d9c94301Cc69167aBa69a6e0e5d86AB66` | [Arbiscan](https://sepolia.arbiscan.io/address/0xC7e28c8d9c94301Cc69167aBa69a6e0e5d86AB66) |

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
