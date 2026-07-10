#!/bin/sh
# Tests for hooks/pr-template-check-cursor.sh.
#
# Each case feeds a real beforeShellExecution payload (JSON on stdin)
# to the hook and checks the permission JSON on stdout. No mocks or
# stubs; the hook (a thin envelope over check-pr-template.sh) runs
# exactly as Cursor would invoke it. The wrapper must always exit 0 —
# Cursor treats non-JSON or crashes as fail-open, and this hook never
# relies on that. JSON validity is checked with python3 when available
# (tests may use python3 — the hook itself must not).
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
HOOK="$REPO/hooks/pr-template-check-cursor.sh"
failures=0

# A body with the Testing section removed; blocked under the skill's
# default headings. Newlines are the literal \n a JSON-encoded command
# carries; the check scans substrings, so the encoding does not matter.
missing_testing='## Summary\ns\n## Motivation\nm\n## Changes\n- c'

# payload <cwd> <command>: wrap a shell command in a
# beforeShellExecution-shaped envelope, cwd first as Cursor sends it.
payload() {
    printf '{"command":"%s","cwd":"%s","hook_event_name":"beforeShellExecution"}' "$2" "$1"
}

# assert_contains <haystack> <needle> <case description>
assert_contains() {
    case "$1" in
        *"$2"*) printf 'PASS: %s\n' "$3" ;;
        *) printf 'FAIL: %s (missing: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
    esac
}

# run_hook <payload>: run the hook and print its stdout. The caller
# captures the exit status into $status right after and checks it with
# assert_exit0 — the increment cannot live here because command
# substitution runs this function in a subshell.
run_hook() {
    printf '%s' "$1" | sh "$HOOK"
}

# assert_exit0 <case description>: the wrapper must always exit 0.
assert_exit0() {
    if [ "$status" -eq 0 ]; then
        printf 'PASS: %s\n' "$1"
    else
        printf 'FAIL: %s (exit %s)\n' "$1" "$status"; failures=$((failures + 1))
    fi
}

# Case 1: a command unrelated to pull requests is allowed.
work=$(mktemp -d)
out=$(run_hook "$(payload "$work" 'git status')") ; status=$?
assert_exit0 'case 1: hook exits 0'
assert_contains "$out" '"permission":"allow"' 'case 1: non-PR command allowed'
rm -rf "$work"

# Case 2: an incomplete inline body is denied and agent_message names
# the missing section. The temp cwd is not a git repo, so the skill's
# default headings apply.
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

# Case 3: a complete inline body is allowed.
work=$(mktemp -d)
complete='## Summary\ns\n## Motivation\nm\n## Changes\n- c\n## Testing\nt'
out=$(run_hook "$(payload "$work" "gh pr create --title x --body '$complete'")") ; status=$?
assert_exit0 'case 3: hook exits 0 on allow'
assert_contains "$out" '"permission":"allow"' 'case 3: complete body allowed'
rm -rf "$work"

# Case 4: the payload cwd selects the repo whose template applies —
# Cursor user-level hooks run from ~/.cursor, never from the project.
# Citing the template file proves the payload field was used.
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
