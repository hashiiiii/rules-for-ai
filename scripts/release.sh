#!/bin/sh
# Bump the plugin version in all three manifests, commit, tag, and push.
# Usage: scripts/release.sh <new-version>   e.g. scripts/release.sh 0.2.0
set -eu

[ $# -eq 1 ] || { printf 'usage: scripts/release.sh <new-version>\n' >&2; exit 1; }
new="$1"
case "$new" in
    [0-9]*.[0-9]*.[0-9]*) ;;
    *) printf 'not a semver version: %s\n' "$new" >&2; exit 1 ;;
esac

# Refuse to run with a dirty index: git commit would sweep staged
# unrelated changes into the release commit and push them.
git diff --cached --quiet || { printf 'index not empty; commit or unstage first\n' >&2; exit 1; }

for manifest in .claude-plugin/plugin.json .codex-plugin/plugin.json .cursor-plugin/plugin.json; do
    sed -i.bak "s/\"version\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"version\": \"$new\"/" "$manifest"
    rm -f "$manifest.bak"
done

scripts/check-versions.sh

git add .claude-plugin/plugin.json .codex-plugin/plugin.json .cursor-plugin/plugin.json
git commit -m "build: release v$new"
git tag "v$new"
git push origin HEAD "v$new"
