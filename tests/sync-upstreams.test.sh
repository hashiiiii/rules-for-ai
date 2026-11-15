#!/bin/sh
# Real Git remotes exercise fetching and patch failures without replacing Git commands.
set -eu
REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
python3 "$REPO/tests/sync_upstreams_test.py"
