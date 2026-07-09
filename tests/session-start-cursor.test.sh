#!/bin/sh
# Tests for hooks/session-start-cursor.sh.
#
# The hook is copied into target repos as
# .cursor/rules-for-ai/session-start-cursor.sh (sibling of
# resolve-locale.sh) and must emit a single-line
# {"additional_context": ...} JSON object on stdout; Cursor injects
# that text into the model context. Each case runs the real script
# against real files; JSON validity is checked with python3 when
# available (tests may use python3 — the hook itself must not).
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
HOOK="$REPO/hooks/session-start-cursor.sh"
failures=0

# assert_contains <haystack> <needle> <case description>
assert_contains() {
    case "$1" in
        *"$2"*) printf 'PASS: %s\n' "$3" ;;
        *) printf 'FAIL: %s (missing: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
    esac
}

# run_hook <fixture root>: run the hook with config isolated to the
# fixture. Cursor feeds hook input JSON on stdin; the hook must consume
# and ignore it.
run_hook() {
    printf '{"conversation_id":"fixture"}' \
        | XDG_CONFIG_HOME="$1/config" HOME="$1" sh "$HOOK"
}

# Case 1: user LOCALE.md present -> its keys ride inside
# additional_context with newlines encoded as literal \n, on one line.
root=$(mktemp -d)
mkdir -p "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=ja_JP
pull-requests=ja_JP
comments=ja_JP
logs=ja_JP
test-logs=ja_JP
EOF
out=$(run_hook "$root")
assert_contains "$out" '{"additional_context":"' 'case 1: JSON envelope present'
assert_contains "$out" '## Locale (resolved)' 'case 1: resolved header in body'
assert_contains "$out" 'issues=ja_JP\npull-requests=ja_JP' 'case 1: keys joined with literal backslash-n'
lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
if [ "$lines" -eq 1 ]; then
    printf 'PASS: case 1: output is a single line\n'
else
    printf 'FAIL: case 1: expected 1 line, got %s\n' "$lines"; failures=$((failures + 1))
fi
rm -rf "$root"

# Case 2: no user file -> the resolver's inline en_US default (project
# installs carry no bundled LOCALE.default.md to fall back to).
root=$(mktemp -d)
out=$(run_hook "$root")
assert_contains "$out" 'issues=en_US' 'case 2: inline default provides issues'
assert_contains "$out" 'test-logs=en_US' 'case 2: inline default provides test-logs'
rm -rf "$root"

# Case 3: double quotes and backslashes in values must be JSON-escaped,
# and the whole envelope must parse as JSON.
root=$(mktemp -d)
mkdir -p "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=en_US "quoted" back\slash
pull-requests=en_US
comments=en_US
logs=en_US
test-logs=en_US
EOF
out=$(run_hook "$root")
assert_contains "$out" '\"quoted\"' 'case 3: double quotes escaped'
assert_contains "$out" 'back\\slash' 'case 3: backslash escaped'
if command -v python3 > /dev/null 2>&1; then
    if printf '%s' "$out" | python3 -c '
import json, sys
d = json.load(sys.stdin)
body = d["additional_context"]
assert "\"quoted\"" in body, body
assert "back\\slash" in body, body
assert body.startswith("## Locale (resolved)"), body
'; then
        printf 'PASS: case 3: envelope parses as JSON and round-trips\n'
    else
        printf 'FAIL: case 3: invalid JSON envelope\n'; failures=$((failures + 1))
    fi
else
    printf 'SKIP: case 3 JSON round-trip (python3 not on PATH)\n'
fi
rm -rf "$root"

# Case 4: the hook must exit 0 even when HOME and XDG_CONFIG_HOME are
# truly unset; session start must never break.
printf '{}' | env -u HOME -u XDG_CONFIG_HOME sh "$HOOK" > /dev/null 2>&1
status=$?
if [ "$status" -eq 0 ]; then
    printf 'PASS: case 4: exit 0 with HOME and XDG_CONFIG_HOME unset\n'
else
    printf 'FAIL: case 4: exit status %s\n' "$status"; failures=$((failures + 1))
fi

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
