#!/bin/sh
# These tests write to the plugin cache on the machine.
# The environment condition makes the script optional for local runs.
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
failures=0
# shellcheck source=tests/rules-for-ai-test-lib.sh
. "$REPO/tests/rules-for-ai-test-lib.sh"

if [ "${RULES_FOR_AI_E2E:-}" != 1 ] || ! command -v claude > /dev/null 2>&1; then
    printf 'SKIP: claude e2e (set RULES_FOR_AI_E2E=1 with claude on PATH)\n'
    exit 0
fi

src=$(new_source_repo)
tgt=$(new_target_repo)

RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" install claude project "$tgt" > /dev/null
settings="$tgt/.claude/settings.json"
assert_file "$settings" 'project scope writes settings.json'
assert_contains "$(cat "$settings")" '"rfa-test@rfa-mkt": true' 'project scope enables the plugin'
RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" uninstall claude project "$tgt" > /dev/null
assert_not_contains "$(cat "$settings")" '"rfa-test@rfa-mkt": true' 'project uninstall disables the plugin'

RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" install claude local "$tgt" > /dev/null
assert_contains "$(cat "$tgt/.claude/settings.local.json")" '"rfa-test@rfa-mkt": true' 'local scope enables the plugin'
RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" uninstall claude local "$tgt" > /dev/null

home=$(mktemp -d)
HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" install claude user > /dev/null
assert_contains "$(cat "$home/.claude/settings.json")" '"rfa-test@rfa-mkt": true' 'user scope enables the plugin'
HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" uninstall claude user > /dev/null
assert_not_contains "$(cat "$home/.claude/settings.json")" '"rfa-test@rfa-mkt": true' 'user uninstall disables the plugin'

rm -rf "$src" "$tgt" "$home"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
