Submission package instructions

Prepare a compressed submission archive for course grading or PR review.

1. Run tests and checks locally:

```bash
source .env
forge test -vv
forge build
forge fmt --check
```

2. (Optional) Run Slither and save report (see `docs/SLITHER_RUN.md`).

3. Create deployments artifact if deploying to testnet:

```bash
# After broadcasting deploy script
DEPLOYMENT_JSON=deployments/arbitrum-sepolia.json \
  forge script script/VerifyDeployment.s.sol:VerifyDeployment --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" -vvv \
  | tee deployments/verification-arbitrum-sepolia.txt
```

4. Create archive with `git archive` (recommended, excludes .git):

```bash
# from repository root
git archive --format zip --output ../final_blockchain_technologies-submission.zip HEAD
```

5. Alternatively use the provided helper script:

```bash
chmod +x scripts/package-submission.sh
./scripts/package-submission.sh
```

6. Attach `final_blockchain_technologies-submission.zip` to your submission or open a PR with the archive and link to the deployment artifact.
