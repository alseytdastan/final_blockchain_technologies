# Arbitrum Sepolia Deployment

Network: Arbitrum Sepolia  
Chain ID: 421614  
Deployer: `0x9b4fFf440Ab7422798ff47713340C7d3125bf33b`

## Contract Addresses

| Component | Address |
|---|---|
| Mock USD Coin (`tokenA`) | `0x0F30c9FD7686Ed10bd8B46314334Bc54D3fdDea9` |
| Mock Wrapped Ether (`tokenB`) | `0x26712554d047cB7cD9de4415c034d462e42E5bae` |
| Governance Token | `0xED26c0b3957DDa22875F6aFFc175d24E2c63b84e` |
| Timelock | `0x69e2da3764113Aad738d79406853Cb5f0379441B` |
| Governor | `0xb7B84a6fE169Da2C1A979048C831327B4071CE11` |
| Treasury | `0x10Ddc0C1303D628ca0a7e2D5956f43086949944C` |
| Mock ETH/USD Aggregator | `0x41595e02346F5B7AB30B55361d6Bbd311457214d` |
| Chainlink Price Adapter | `0x4858D8eAfC15a1E9381A7f6F6F36f1b2b52b10A7` |
| Pool Factory | `0xF9eDd2Fbd47AA7484C2DB84495eE86403f54d40c` |
| AMM Pool | `0x176de48AC9F70207023994929C35858070689129` |
| LP Token | `0x8706980c1Ad5b739D88d37270009138287feE162` |
| ERC-4626 Vault | `0xB25f3B93EaC9bE7EcC9eA6D5bF0B024A2FB6a45E` |
| Lending Pool | `0x0617Df7A719B5c571619B6A6E32b113EB637b6E8` |
| Protocol Access NFT | `0x9c489BB471d12b54A0D401581cDf858d0AfB05fc` |
| Config Implementation | `0x46763A870C791b754d22cBbb6F9b2587EE9F2186` |
| Config Proxy | `0x3Ab9Ec8F39AbeCD645E939c4810E0c51c5f9eD06` |

## Verification Script

The post-deployment verification script was executed successfully against Arbitrum Sepolia.

```bash
DEPLOYER=0x9b4fFf440Ab7422798ff47713340C7d3125bf33b \
TOKEN_A=0x0F30c9FD7686Ed10bd8B46314334Bc54D3fdDea9 \
TOKEN_B=0x26712554d047cB7cD9de4415c034d462e42E5bae \
GOVERNANCE_TOKEN=0xED26c0b3957DDa22875F6aFFc175d24E2c63b84e \
TIMELOCK=0x69e2da3764113Aad738d79406853Cb5f0379441B \
GOVERNOR=0xb7B84a6fE169Da2C1A979048C831327B4071CE11 \
TREASURY=0x10Ddc0C1303D628ca0a7e2D5956f43086949944C \
POOL=0x176de48AC9F70207023994929C35858070689129 \
VAULT=0xB25f3B93EaC9bE7EcC9eA6D5bF0B024A2FB6a45E \
LENDING_POOL=0x0617Df7A719B5c571619B6A6E32b113EB637b6E8 \
BADGE=0x9c489BB471d12b54A0D401581cDf858d0AfB05fc \
CONFIG_PROXY=0x3Ab9Ec8F39AbeCD645E939c4810E0c51c5f9eD06 \
forge script script/VerifyDeployment.s.sol --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL"
```

Expected output:

```text
Deployment verification passed
```

## Frontend And Subgraph

The frontend is configured for Arbitrum Sepolia and uses the deployed contract addresses above.

The subgraph manifest is configured for Arbitrum Sepolia contract addresses. The only remaining subgraph value to replace after publishing in The Graph Studio is the frontend `subgraphUrl`.
