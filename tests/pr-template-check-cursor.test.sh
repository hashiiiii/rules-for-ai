#!/bin/sh
# These tests cover hooks/pr-template-check-cursor.sh.
#
# Each case sends a real beforeShellExecution payload to the hook through stdin.
# Then it examines the permission JSON on stdout.
# The tests do not use mocks or stubs.
# Cursor and the tests run the same hook envelope.
# The envelope must always exit 0.
# Cursor permits the command after invalid JSON or a hook crash.
# These tests do not depend on that behavior.
# If python3 is available, it parses the JSON.
# The tests can use python3, but the hook cannot use it.
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
HOOK="$REPO/hooks/pr-template-check-cursor.sh"
failures=0

# This body omits the Testing section, so the default rules block it.
# Literal \n values represent the newlines in a JSON-encoded command.
# The hook scans substrings, so the encoding does not affect the result.
missing_testing='## Summary\ns\n## Motivation\nm\n## Changes\n- c'

# payload <cwd> <command> wraps a shell command in a beforeShellExecution envelope.
# Cursor sends cwd first.
payload() {
    printf '{"command":"%s","cwd":"%s","hook_event_name":"beforeShellExecution"}' "$2" "$1"
}

# assert_contains <haystack> <needle> <case-description> searches the result.
assert_contains() {
    case "$1" in
        *"$2"*) printf 'PASS: %s\n' "$3" ;;
        *) printf 'FAIL: %s (missing: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
    esac
}

# run_hook <payload> runs the hook and prints stdout.
# The caller immediately saves the exit status in $status.
# Then assert_exit0 compares the status.
# The failure increment cannot occur here because command substitution uses a subshell.
run_hook() {
    printf '%s' "$1" | sh "$HOOK"
}

# assert_exit0 <case-description> makes sure that the envelope exits 0.
assert_exit0() {
    if [ "$status" -eq 0 ]; then
        printf 'PASS: %s\n' "$1"
    else
        printf 'FAIL: %s (exit %s)\n' "$1" "$status"; failures=$((failures + 1))
    fi
}

# Case 1 makes sure that the hook permits a non-pull-request command.
work=$(mktemp -d)
out=$(run_hook "$(payload "$work" 'git status')") ; status=$?
assert_exit0 'case 1: hook exits 0'
assert_contains "$out" '"permission":"allow"' 'case 1: non-PR command allowed'
rm -rf "$work"

# Case 2 makes sure that the hook blocks an incomplete inline body.
# The agent_message value must name the omitted section.
# The temporary directory is not a Git repository. Thus, the default headings apply.
work=$(mktemp -d)
out=$(run_hook "$(payload "$work" "gh pr create --title x --body '$missing_testing'")") ; status=$?
assert_exit0 'case 2: hook exits 0 on deny'
assert_contains "$out" '"permission":"deny"' 'case 2: incomplete body denied'
assert_contains "$out" '"agent_message":"' 'case 2: deny carries agent_message'
assert_contains "$out" 'Testing' 'case 2: agent_message names the missing section'
if command -v python3 > /dev/null 2>&1; then
    if printf '%s' "$out" | python3 -c '
import json, sys
d = json.load(sys.stdin)
assert d["permission"] == "deny", d
assert "## Testing" in d["agent_message"], d
'; then
        printf 'PASS: case 2: deny envelope parses as JSON and round-trips\n'
    else
        printf 'FAIL: case 2: invalid JSON envelope\n'; failures=$((failures + 1))
    fi
else
    printf 'SKIP: case 2 JSON round-trip (python3 not on PATH)\n'
fi
rm -rf "$work"

# Case 3 makes sure that the hook permits a complete inline body.
work=$(mktemp -d)
complete='## Summary\ns\n## Motivation\nm\n## Changes\n- c\n## Testing\nt'
out=$(run_hook "$(payload "$work" "gh pr create --title x --body '$complete'")") ; status=$?
assert_exit0 'case 3: hook exits 0 on allow'
assert_contains "$out" '"permission":"allow"' 'case 3: complete body allowed'
rm -rf "$work"

# Case 4 makes sure that the payload cwd selects the template repository.
# Cursor user hooks run from ~/.cursor and not from the project.
# A template citation proves that the hook used the payload field.
template_repo=$(mktemp -d)
(
    cd "$template_repo" || exit 1
    git init -q
    git config user.email 'test@example.com'
    git config user.name 'test'
    mkdir -p .github
    printf '%s\n' '## Description' '## Checklist' > .github/pull_request_template.md
    git add .github/pull_request_template.md
    git commit -q -m 'add template'
)
out=$(run_hook "$(payload "$template_repo" "gh pr create --title x --body '## Description\nd'")") ; status=$?
assert_exit0 'case 4: hook exits 0'
assert_contains "$out" '"permission":"deny"' 'case 4: template repo via payload cwd denies'
assert_contains "$out" 'Checklist' 'case 4: deny names the template section'
assert_contains "$out" 'pull_request_template.md' 'case 4: deny cites the template file'
rm -rf "$template_repo"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
