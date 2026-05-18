#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f .env ]]; then
  echo "Create .env from .env.example (PRIVATE_KEY, ARBITRUM_SEPOLIA_RPC_URL, ETHERSCAN_API_KEY)"
  exit 1
fi

set -a
source .env
set +a

# Defaults when migrating from Base-only .env
export ARBITRUM_SEPOLIA_RPC_URL="${ARBITRUM_SEPOLIA_RPC_URL:-https://sepolia-rollup.arbitrum.io/rpc}"
export ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY:-${BASESCAN_API_KEY:-}}"

if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "Warning: ETHERSCAN_API_KEY not set — deploy will run but --verify may fail."
  echo "Add ETHERSCAN_API_KEY=... to .env (etherscan.io/myapikey, same key often works for Arbiscan)."
fi

forge script script/Deploy.s.sol:Deploy \
  --rpc-url arbitrum_sepolia \
  --broadcast \
  --verify \
  -vvvv

DEPLOYMENT_JSON=deployments/arbitrum-sepolia.json \
  forge script script/VerifyDeployment.s.sol:VerifyDeployment \
  --rpc-url arbitrum_sepolia \
  -vvv | tee deployments/verification-arbitrum-sepolia.txt

echo "Done. Update README Deployment table and frontend/app.js from deployments/arbitrum-sepolia.json"
