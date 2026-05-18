# Arbitrum Sepolia Deployment

Network: Arbitrum Sepolia  
Chain ID: 421614  
Deployer: `0x9b4fFf440Ab7422798ff47713340C7d3125bf33b`

## Contract Addresses

| Component | Address |
|---|---|
| Mock USD Coin (`tokenA`) | `0xEc0Cf7f5559431a1E757419804aD800Cb6d01ab9` |
| Mock Wrapped Ether (`tokenB`) | `0x05aa36A6F5cCD450ae590b6780507975f8BdA0a9` |
| Governance Token | `0xd128e7BdDa0a96AF805839FaD4D5A22365Aea84b` |
| Timelock | `0x8E7354Cf8C131De13255F7ba3e4be253fc6308CF` |
| Governor | `0x930568ABa3Ac134bed2FDE34B162E60dBB09b136` |
| Treasury | `0xB3eAf4CafF78809805642337100d1b1a5A4B6AC7` |
| Mock ETH/USD Aggregator | `0x1D01e03e4efFB1a944e7CFD9D21bD6c685c7156D` |
| Chainlink Price Adapter | `0x0e7Db0BD600bB8A3919302410F55ACA81B15632B` |
| Pool Factory | `0x7612529B986E33e033C23016feEB6D29d27a6d26` |
| AMM Pool | `0x27a14e9c611080B52eaC4Bf59cBeD93d15978719` |
| LP Token | `0xcc1f0968f2bce24516397413B4F0d5B3C86a9afd` |
| ERC-4626 Vault | `0x280E3BcF84299D8f53eB7876a4daA2bAe9d40124` |
| Lending Pool | `0xC409d806B5B5d77d208b7538984DbE15325Dd59b` |
| Protocol Access NFT | `0x49b4d149473ca5e2CFb1B02584EAeD6C030eF6B4` |
| Config Implementation | `0xa4B9308683Da88Ae651209a30535F989Cbc07BC6` |
| Config Proxy | `0x3907a81b9BA32855B48010087f68C70dbdCAE24C` |

## Verification Script

The post-deployment verification script was executed successfully against Arbitrum Sepolia.

```bash
DEPLOYER=0x9b4fFf440Ab7422798ff47713340C7d3125bf33b \
TOKEN_A=0xEc0Cf7f5559431a1E757419804aD800Cb6d01ab9 \
TOKEN_B=0x05aa36A6F5cCD450ae590b6780507975f8BdA0a9 \
GOVERNANCE_TOKEN=0xd128e7BdDa0a96AF805839FaD4D5A22365Aea84b \
TIMELOCK=0x8E7354Cf8C131De13255F7ba3e4be253fc6308CF \
GOVERNOR=0x930568ABa3Ac134bed2FDE34B162E60dBB09b136 \
TREASURY=0xB3eAf4CafF78809805642337100d1b1a5A4B6AC7 \
POOL=0x27a14e9c611080B52eaC4Bf59cBeD93d15978719 \
VAULT=0x280E3BcF84299D8f53eB7876a4daA2bAe9d40124 \
LENDING_POOL=0xC409d806B5B5d77d208b7538984DbE15325Dd59b \
BADGE=0x49b4d149473ca5e2CFb1B02584EAeD6C030eF6B4 \
CONFIG_PROXY=0x3907a81b9BA32855B48010087f68C70dbdCAE24C \
forge script script/VerifyDeployment.s.sol --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL"
```

Expected output:

```text
Deployment verification passed
```

## Frontend And Subgraph

The frontend is configured for Arbitrum Sepolia and uses the deployed contract addresses above.

The subgraph manifest is configured for Arbitrum Sepolia contract addresses. The only remaining subgraph value to replace after publishing in The Graph Studio is the frontend `subgraphUrl`.
