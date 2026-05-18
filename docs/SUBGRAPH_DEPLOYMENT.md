# Subgraph Deployment

The subgraph manifest is configured for Arbitrum Sepolia and the latest addresses in `deployments/arbitrum-sepolia.json`.

## Indexed Contracts

| Data source | Address |
|---|---|
| PoolFactory | `0x7612529B986E33e033C23016feEB6D29d27a6d26` |
| AMMPool | `0x27a14e9c611080B52eaC4Bf59cBeD93d15978719` |
| YieldVault | `0x280E3BcF84299D8f53eB7876a4daA2bAe9d40124` |
| LendingPool | `0xC409d806B5B5d77d208b7538984DbE15325Dd59b` |

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
