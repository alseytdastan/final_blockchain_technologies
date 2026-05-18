# Arbitrum Sepolia Deployment

Network: Arbitrum Sepolia  
Chain ID: 421614  
Deployer: `0x9b4fFf440Ab7422798ff47713340C7d3125bf33b`

## Contract Addresses

| Component | Address |
|---|---|
| Mock USD Coin (`tokenA`) | `0x7abAE8a8217f77CA0EDb60bbd00297aD936a392c` |
| Mock Wrapped Ether (`tokenB`) | `0xF9B62c21F0D9655CaEeC0A21DAeA9409B2678E1A` |
| Governance Token | `0xA0d618c8F07d823416fC98dCC54fc5850Bba3A77` |
| Timelock | `0xAeCF1aF0d940cFFf5da14296a010138891e5b1b3` |
| Governor | `0xdA6E681f08045391C9b342349bFd3DC263f2556F` |
| Treasury | `0x8991EC3E7C563B7ED2cf32cDE04B604193a53D42` |
| Mock ETH/USD Aggregator | `0x0bb9FA9524B1d7fa35d3ad4705609418eFCA474f` |
| Chainlink Price Adapter | `0x84e57E4034FBfbbd14Ee7ed7A1DAe797Bdc5c20d` |
| Pool Factory | `0xd51207288c2B803A3d365a04Bb7C316072a4a3FA` |
| AMM Pool | `0x03b1882CE3EB333A29806c66acD24AaeB7F8eC7B` |
| LP Token | `0x2043C10B0F33bd072d3135fb578Ff12011A6529e` |
| ERC-4626 Vault | `0x1F248BF5FFa817d5658253AF86ffCFB8e6710715` |
| Lending Pool | `0x89e6a15EA06342622b9cff3Ee5F1C1ed9a7102F9` |
| Protocol Access NFT | `0x138678BDD4A68d461a91DD67eF9DbDFb0e653d58` |
| Config Implementation | `0x4bCc11169dF1E1Cdefb6eDe8b1c5a67D398124c9` |
| Config Proxy | `0xC7e28c8d9c94301Cc69167aBa69a6e0e5d86AB66` |

## Verification Script

The post-deployment verification script was executed successfully against Arbitrum Sepolia.

```bash
DEPLOYER=0x9b4fFf440Ab7422798ff47713340C7d3125bf33b \
TOKEN_A=0x7abAE8a8217f77CA0EDb60bbd00297aD936a392c \
TOKEN_B=0xF9B62c21F0D9655CaEeC0A21DAeA9409B2678E1A \
GOVERNANCE_TOKEN=0xA0d618c8F07d823416fC98dCC54fc5850Bba3A77 \
TIMELOCK=0xAeCF1aF0d940cFFf5da14296a010138891e5b1b3 \
GOVERNOR=0xdA6E681f08045391C9b342349bFd3DC263f2556F \
TREASURY=0x8991EC3E7C563B7ED2cf32cDE04B604193a53D42 \
POOL=0x03b1882CE3EB333A29806c66acD24AaeB7F8eC7B \
VAULT=0x1F248BF5FFa817d5658253AF86ffCFB8e6710715 \
LENDING_POOL=0x89e6a15EA06342622b9cff3Ee5F1C1ed9a7102F9 \
BADGE=0x138678BDD4A68d461a91DD67eF9DbDFb0e653d58 \
CONFIG_PROXY=0xC7e28c8d9c94301Cc69167aBa69a6e0e5d86AB66 \
forge script script/VerifyDeployment.s.sol --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL"
```

Expected output:

```text
Deployment verification passed
```

## Frontend And Subgraph

The frontend is configured for Arbitrum Sepolia and uses the deployed contract addresses above.

The subgraph manifest is configured for Arbitrum Sepolia contract addresses. The only remaining subgraph value to replace after publishing in The Graph Studio is the frontend `subgraphUrl`.
