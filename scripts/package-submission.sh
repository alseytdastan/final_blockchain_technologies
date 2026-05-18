#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Running tests..."
forge test -q || true

echo "Formatting check..."
forge fmt --check || true

ZIP_NAME="../final_blockchain_technologies-submission.zip"

echo "Creating archive $ZIP_NAME"
git archive --format zip --output "$ZIP_NAME" HEAD

echo "Archive created: $ZIP_NAME"
