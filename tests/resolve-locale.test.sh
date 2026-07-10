#!/bin/sh
# Tests for hooks/resolve-locale.sh.
#
# The resolver is the single source of locale resolution logic shared
# by the Claude and Cursor session-start wrappers: first existing
# candidate wins as a whole, inline en_US when none exists. Each case
# runs the real script against real files under a temp root; no mocks
# or stubs.
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
RESOLVER="$REPO/hooks/resolve-locale.sh"
failures=0

# assert_contains <haystack> <needle> <case description>
assert_contains() {
    case "$1" in
        *"$2"*) printf 'PASS: %s\n' "$3" ;;
        *) printf 'FAIL: %s (missing: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
    esac
}

# assert_not_contains <haystack> <needle> <case description>
assert_not_contains() {
    case "$1" in
        *"$2"*) printf 'FAIL: %s (unexpected: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
        *) printf 'PASS: %s\n' "$3" ;;
    esac
}

root=$(mktemp -d)
cat > "$root/first.md" <<'EOF'
issues=ja_JP
pull-requests=ja_JP
comments=ja_JP
logs=ja_JP
test-logs=ja_JP
EOF
cat > "$root/second.md" <<'EOF'
issues=en_GB
pull-requests=en_GB
comments=en_GB
logs=en_GB
test-logs=en_GB
EOF

# Case 1: the first existing candidate wins as a whole; later
# candidates never merge in.
out=$(sh "$RESOLVER" "$root/first.md" "$root/second.md")
assert_contains "$out" 'issues=ja_JP' 'case 1: first candidate wins'
assert_not_contains "$out" 'en_GB' 'case 1: layers never merge'

# Case 2: a missing first candidate falls through to the second.
out=$(sh "$RESOLVER" "$root/missing.md" "$root/second.md")
assert_contains "$out" 'issues=en_GB' 'case 2: falls through to the next candidate'

# Case 3: prose around the keys is filtered out. The real bundled
# LOCALE.default.md carries explanatory text above the keys; only the
# five key lines may pass through.
out=$(sh "$RESOLVER" "$REPO/LOCALE.default.md")
assert_contains "$out" 'issues=en_US' 'case 3: bundled default resolves'
assert_not_contains "$out" '# Locale' 'case 3: prose is filtered'
lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
if [ "$lines" -eq 5 ]; then
    printf 'PASS: case 3: exactly five key lines\n'
else
    printf 'FAIL: case 3: expected 5 lines, got %s\n' "$lines"; failures=$((failures + 1))
fi

# Case 4: no candidate exists -> the inline en_US default provides all
# five keys, so a resolved block is never empty.
out=$(sh "$RESOLVER" "$root/missing.md")
assert_contains "$out" 'issues=en_US' 'case 4: inline default provides issues'
assert_contains "$out" 'pull-requests=en_US' 'case 4: inline default provides pull-requests'
assert_contains "$out" 'comments=en_US' 'case 4: inline default provides comments'
assert_contains "$out" 'logs=en_US' 'case 4: inline default provides logs'
assert_contains "$out" 'test-logs=en_US' 'case 4: inline default provides test-logs'

# Case 5: no arguments at all -> inline default, exit 0.
out=$(sh "$RESOLVER") && rc=0 || rc=$?
assert_contains "$out" 'issues=en_US' 'case 5: no args yields inline default'
if [ "$rc" -eq 0 ]; then
    printf 'PASS: case 5: exit 0 with no args\n'
else
    printf 'FAIL: case 5: exit status %s\n' "$rc"; failures=$((failures + 1))
fi

rm -rf "$root"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
