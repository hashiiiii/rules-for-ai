#!/bin/sh
# This test uses the real Codex CLI with an isolated CODEX_HOME.
# It verifies the marketplace, installed plugin files, and removal path.
set -u

if [ "${RULES_FOR_AI_E2E:-}" != 1 ]; then
    printf 'SKIP: set RULES_FOR_AI_E2E=1 to run the Codex plugin e2e test\n'
    exit 0
fi

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
failures=0
# shellcheck source=tests/rules-for-ai-test-lib.sh
. "$REPO/tests/rules-for-ai-test-lib.sh"

codex_home=$(mktemp -d)
trap 'rm -rf "$codex_home"' EXIT

out=$(CODEX_HOME="$codex_home" codex plugin marketplace add "$REPO" --json)
assert_contains "$out" '"marketplaceName": "hashiiiii"' 'marketplace registers from the repository'

out=$(CODEX_HOME="$codex_home" codex plugin add rules-for-ai@hashiiiii --json)
assert_contains "$out" '"name": "rules-for-ai"' 'plugin installs from the marketplace'
version=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$REPO/.codex-plugin/plugin.json" | head -n 1)
assert_contains "$out" "\"version\": \"$version\"" 'plugin install reads the manifest version'
installed=$(printf '%s\n' "$out" | sed -n 's/.*"installedPath": "\([^"]*\)".*/\1/p')
assert_file "$installed/skills/hashiiiii-git/SKILL.md" 'installed plugin contains the Git skill'
assert_file "$installed/hooks/hooks.json" 'installed plugin contains the shared hooks'

CODEX_HOME="$codex_home" codex plugin remove rules-for-ai@hashiiiii --json > /dev/null
out=$(CODEX_HOME="$codex_home" codex plugin list)
assert_contains "$out" 'not installed' 'plugin removal disables the plugin'

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
