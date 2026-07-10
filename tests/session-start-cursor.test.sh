#!/bin/sh
# Tests for hooks/session-start-cursor.sh.
#
# The hook ships in two layouts: copied into a target repo as
# .cursor/rules-for-ai/session-start-cursor.sh (siblings:
# resolve-locale.sh, json-escape.sh, LOCALE.default.md), or inside the
# user-scope plugin clone as <clone>/hooks/session-start-cursor.sh with
# LOCALE.default.md at the clone root. Each case copies the real
# scripts into a real layout under a temp root and runs them there —
# running from the repo would let the repo's own LOCALE.default.md
# shadow the layer under test. The hook must emit a single-line
# {"additional_context": ...} JSON object on stdout; JSON validity is
# checked with python3 when available (tests may use python3 — the hook
# itself must not).
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
failures=0

# assert_contains <haystack> <needle> <case description>
assert_contains() {
    case "$1" in
        *"$2"*) printf 'PASS: %s\n' "$3" ;;
        *) printf 'FAIL: %s (missing: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
    esac
}

# install_scripts <dir>: place the hook and its script siblings the way
# both install layouts do.
install_scripts() {
    mkdir -p "$1"
    cp "$REPO/hooks/session-start-cursor.sh" "$1/session-start-cursor.sh"
    cp "$REPO/hooks/resolve-locale.sh" "$1/resolve-locale.sh"
    cp "$REPO/hooks/json-escape.sh" "$1/json-escape.sh"
}

# run_hook <hook dir> <fixture root>: run the installed hook with user
# config isolated to the fixture. Cursor feeds hook input JSON on
# stdin; the hook must consume and ignore it.
run_hook() {
    printf '{"conversation_id":"fixture"}' \
        | XDG_CONFIG_HOME="$2/config" HOME="$2" sh "$1/session-start-cursor.sh"
}

# Case 1: user LOCALE.md beats the sibling LOCALE.default.md, and the
# keys ride inside additional_context with newlines encoded as literal
# \n, on one line.
root=$(mktemp -d)
install_scripts "$root/.cursor/rules-for-ai"
printf 'issues=xx_XX\n' > "$root/.cursor/rules-for-ai/LOCALE.default.md"
mkdir -p "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=ja_JP
pull-requests=ja_JP
comments=ja_JP
logs=ja_JP
test-logs=ja_JP
EOF
out=$(run_hook "$root/.cursor/rules-for-ai" "$root")
assert_contains "$out" '{"additional_context":"' 'case 1: JSON envelope present'
assert_contains "$out" '## Locale (resolved)' 'case 1: resolved header in body'
assert_contains "$out" 'issues=ja_JP\npull-requests=ja_JP' 'case 1: user keys win, joined with literal backslash-n'
lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
if [ "$lines" -eq 1 ]; then
    printf 'PASS: case 1: output is a single line\n'
else
    printf 'FAIL: case 1: expected 1 line, got %s\n' "$lines"; failures=$((failures + 1))
fi
rm -rf "$root"

# Case 2: project/local layout without a user file -> the copied
# sibling LOCALE.default.md wins. The distinctive tag proves the copy
# was read rather than the inline default.
root=$(mktemp -d)
install_scripts "$root/.cursor/rules-for-ai"
printf 'issues=xx_XX\npull-requests=xx_XX\ncomments=xx_XX\nlogs=xx_XX\ntest-logs=xx_XX\n' \
    > "$root/.cursor/rules-for-ai/LOCALE.default.md"
out=$(run_hook "$root/.cursor/rules-for-ai" "$root")
assert_contains "$out" 'issues=xx_XX' 'case 2: sibling LOCALE.default.md provides the keys'
rm -rf "$root"

# Case 3: user-scope plugin clone layout (hooks/ subdir) without a user
# file -> the clone-root LOCALE.default.md wins via the parent lookup.
root=$(mktemp -d)
install_scripts "$root/plugin/hooks"
printf 'issues=yy_YY\npull-requests=yy_YY\ncomments=yy_YY\nlogs=yy_YY\ntest-logs=yy_YY\n' \
    > "$root/plugin/LOCALE.default.md"
out=$(run_hook "$root/plugin/hooks" "$root")
assert_contains "$out" 'issues=yy_YY' 'case 3: clone-root LOCALE.default.md provides the keys'
rm -rf "$root"

# Case 4: no user file and no LOCALE.default.md anywhere -> the
# resolver's inline en_US backstop keeps the block non-empty.
root=$(mktemp -d)
install_scripts "$root/bare"
out=$(run_hook "$root/bare" "$root")
assert_contains "$out" 'issues=en_US' 'case 4: inline default provides issues'
assert_contains "$out" 'test-logs=en_US' 'case 4: inline default provides test-logs'
rm -rf "$root"

# Case 5: double quotes and backslashes in values must be JSON-escaped,
# and the whole envelope must parse as JSON.
root=$(mktemp -d)
install_scripts "$root/bare"
mkdir -p "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=en_US "quoted" back\slash
pull-requests=en_US
comments=en_US
logs=en_US
test-logs=en_US
EOF
out=$(run_hook "$root/bare" "$root")
assert_contains "$out" '\"quoted\"' 'case 5: double quotes escaped'
assert_contains "$out" 'back\\slash' 'case 5: backslash escaped'
if command -v python3 > /dev/null 2>&1; then
    if printf '%s' "$out" | python3 -c '
import json, sys
d = json.load(sys.stdin)
body = d["additional_context"]
assert "\"quoted\"" in body, body
assert "back\\slash" in body, body
assert body.startswith("## Locale (resolved)"), body
'; then
        printf 'PASS: case 5: envelope parses as JSON and round-trips\n'
    else
        printf 'FAIL: case 5: invalid JSON envelope\n'; failures=$((failures + 1))
    fi
else
    printf 'SKIP: case 5 JSON round-trip (python3 not on PATH)\n'
fi
rm -rf "$root"

# Case 6: the hook must exit 0 even when HOME and XDG_CONFIG_HOME are
# truly unset; session start must never break.
root=$(mktemp -d)
install_scripts "$root/bare"
printf '{}' | env -u HOME -u XDG_CONFIG_HOME sh "$root/bare/session-start-cursor.sh" > /dev/null 2>&1
status=$?
if [ "$status" -eq 0 ]; then
    printf 'PASS: case 6: exit 0 with HOME and XDG_CONFIG_HOME unset\n'
else
    printf 'FAIL: case 6: exit status %s\n' "$status"; failures=$((failures + 1))
fi
rm -rf "$root"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
