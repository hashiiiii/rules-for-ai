#!/bin/sh
# Tests for hooks/pr-template-check.sh.
#
# Each case feeds a real PreToolUse payload (JSON on stdin) to the hook
# and checks the exit status, plus the stderr guidance for blocks. No
# mocks or stubs; the hook runs exactly as Claude Code would invoke it.
#
# The hook validates only inline bodies, so file-backed (--body-file) and
# auto-filled (--fill) bodies must always pass — it fails open rather than
# risk a false block.
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
HOOK="$REPO/hooks/pr-template-check.sh"
failures=0

# A complete inline body carrying all four required headings. Newlines are
# written as the literal \n a JSON-encoded command would contain; the hook
# scans substrings, so the encoding does not matter.
body='## Summary\nwhat\n## Motivation\nwhy\n## Changes\n- x\n## Testing\nran zig build test'
# The same body with the Testing section removed.
missing_testing='## Summary\ns\n## Motivation\nm\n## Changes\n- c'

# payload <command>: wrap a Bash command in a PreToolUse-shaped envelope.
payload() {
    printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"
}

# assert_exit <description> <expected status> <payload>
assert_exit() {
    printf '%s' "$3" | sh "$HOOK" > /dev/null 2>&1
    got=$?
    if [ "$got" -eq "$2" ]; then
        printf 'PASS: %s\n' "$1"
    else
        printf 'FAIL: %s (exit %s, want %s)\n' "$1" "$got" "$2"
        failures=$((failures + 1))
    fi
}

# assert_block_mentions <description> <needle> <payload>
assert_block_mentions() {
    err=$(printf '%s' "$3" | sh "$HOOK" 2>&1 > /dev/null)
    case "$err" in
        *"$2"*) printf 'PASS: %s\n' "$1" ;;
        *) printf 'FAIL: %s (stderr missing: %s)\n' "$1" "$2"
            failures=$((failures + 1)) ;;
    esac
}

# A command unrelated to pull requests is never touched.
assert_exit 'non-PR command passes' 0 "$(payload 'git status')"

# A create with all four headings inline is allowed.
assert_exit 'complete inline body passes' 0 \
    "$(payload "gh pr create --title x --body '$body'")"

# A create missing one heading is blocked, and the reason names it.
assert_exit 'missing Testing is blocked' 2 \
    "$(payload "gh pr create --title x --body '$missing_testing'")"
assert_block_mentions 'block reason names the missing section' 'Testing' \
    "$(payload "gh pr create --title x --body '$missing_testing'")"

# A body loaded from a file cannot be inspected, so it must pass.
assert_exit 'body-file fails open' 0 \
    "$(payload 'gh pr create --title x --body-file body.md')"

# gh --fill builds the body itself; nothing to validate, so it passes.
assert_exit 'fill fails open' 0 \
    "$(payload 'gh pr create --title x --fill')"

# A create with no body flag opens the editor; do not block it.
assert_exit 'no body flag fails open' 0 \
    "$(payload 'gh pr create --title x')"

# Editing a body is enforced the same way as creating one.
assert_exit 'edit with incomplete body is blocked' 2 \
    "$(payload "gh pr edit 12 --body '$missing_testing'")"
assert_block_mentions 'edit block names the missing section' 'Motivation' \
    "$(payload "gh pr edit 12 --body '## Summary\ns\n## Changes\n- c\n## Testing\nt'")"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
