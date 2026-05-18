# Subgraph Deployment

The subgraph manifest is configured for Arbitrum Sepolia and the latest addresses in `deployments/arbitrum-sepolia.json`.

## Indexed Contracts

| Data source | Address |
|---|---|
| PoolFactory | `0xd51207288c2B803A3d365a04Bb7C316072a4a3FA` |
| AMMPool | `0x03b1882CE3EB333A29806c66acD24AaeB7F8eC7B` |
| YieldVault | `0x1F248BF5FFa817d5658253AF86ffCFB8e6710715` |
| LendingPool | `0x89e6a15EA06342622b9cff3Ee5F1C1ed9a7102F9` |

## Build

```bash
cd subgraph
npm install
npm run codegen
npm run build
```

Generated AssemblyScript bindings are created under `subgraph/generated/` by `npm run codegen`.

## Publish To The Graph Studio

Create a `defihub` subgraph in The Graph Studio, then run:

```bash
cd subgraph
export GRAPH_DEPLOY_KEY=<the-graph-studio-deploy-key>
npm run auth
npm run deploy
```

After publishing, replace `YOUR_SUBGRAPH_ID` in `frontend/app.js` with the numeric Studio query id:

```text
https://api.studio.thegraph.com/query/<SUBGRAPH_ID>/defihub/version/latest
```

## Required Query Checks

Run the five queries in `subgraph/queries.graphql` after the Studio indexer syncs:

- `RecentSwaps`
- `Pools`
- `VaultAccounts`
- `LoanPositions`
- `RecentLiquidations`

Record the successful query responses or screenshots before final submission.
