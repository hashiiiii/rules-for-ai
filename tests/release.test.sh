#!/bin/sh
# Tests for scripts/release.sh and scripts/check-versions.sh.
#
# Builds a throwaway git repo containing the three manifests and a local
# bare remote, then performs a real release: commit, tag, and push are
# all exercised for real. No mocks or stubs.
set -eu

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

# Arrange: a work repo with all manifests at 0.0.1 and a bare origin.
git init -q "$root/work"
git init -q --bare "$root/origin.git"
cd "$root/work"
git remote add origin "$root/origin.git"
git config user.email test@example.com
git config user.name test
mkdir -p .claude-plugin .codex-plugin .cursor-plugin scripts
for m in .claude-plugin .codex-plugin .cursor-plugin; do
    printf '{\n  "name": "rules-for-ai",\n  "version": "0.0.1"\n}\n' > "$m/plugin.json"
done
cp "$REPO/scripts/release.sh" scripts/release.sh
cp "$REPO/scripts/check-versions.sh" scripts/check-versions.sh
git add -A
git commit -qm "chore: seed fixture repo"
git branch -q -M main
git push -qu origin main

# Sanity: the lockstep check passes on the seeded state.
scripts/check-versions.sh | grep -q '0.0.1' || { printf 'FAIL: seed check\n'; exit 1; }
printf 'PASS: check-versions accepts lockstep manifests\n'

# A deliberate mismatch must be rejected.
printf '{\n  "name": "rules-for-ai",\n  "version": "9.9.9"\n}\n' > .cursor-plugin/plugin.json
if scripts/check-versions.sh > /dev/null 2>&1; then
    printf 'FAIL: check-versions accepted a mismatch\n'
    exit 1
fi
printf 'PASS: check-versions rejects a mismatch\n'
git checkout -- .cursor-plugin/plugin.json

# A dirty index must abort the release: git commit would sweep staged
# unrelated files into the release commit and push them.
printf 'unrelated\n' > unrelated.txt
git add unrelated.txt
if scripts/release.sh 0.9.9 > /dev/null 2>&1; then
    printf 'FAIL: release accepted a dirty index\n'
    exit 1
fi
printf 'PASS: release refuses a dirty index\n'
git rm -q --cached unrelated.txt
rm -f unrelated.txt

# Act: a real release.
scripts/release.sh 0.2.0

# Assert: manifests bumped in lockstep, tag present on the remote.
scripts/check-versions.sh | grep -q '0.2.0' || { printf 'FAIL: manifests not bumped\n'; exit 1; }
printf 'PASS: release bumps all manifests\n'
git ls-remote --tags origin | grep -q 'refs/tags/v0.2.0' || { printf 'FAIL: tag not pushed\n'; exit 1; }
printf 'PASS: release pushes the tag\n'

printf 'all release tests passed\n'
