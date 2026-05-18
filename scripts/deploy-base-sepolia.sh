#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f .env ]]; then
  echo "Create .env from .env.example (PRIVATE_KEY, BASE_SEPOLIA_RPC_URL, BASESCAN_API_KEY)"
  exit 1
fi

set -a
source .env
set +a

forge script script/Deploy.s.sol:Deploy \
  --rpc-url base_sepolia \
  --broadcast \
  --verify \
  -vvvv

forge script script/VerifyDeployment.s.sol:VerifyDeployment \
  --rpc-url base_sepolia \
  -vvv | tee deployments/verification-base-sepolia.txt

echo "Done. Update README Deployment table and frontend/app.js from deployments/base-sepolia.json"
