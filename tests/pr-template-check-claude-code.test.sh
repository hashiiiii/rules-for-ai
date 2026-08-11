#!/bin/sh
# These tests cover hooks/pr-template-check-claude-code.sh.
#
# Each case sends a real PreToolUse payload to the hook through stdin.
# Then it compares the exit status and examines the block message on stderr.
# The tests do not use mocks or stubs.
# Claude Code and the tests run the same hook envelope.
#
# The hook evaluates only inline bodies.
# Thus, it must permit bodies from --body-file or --fill to prevent an incorrect block.
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
HOOK="$REPO/hooks/pr-template-check-claude-code.sh"
failures=0

# This complete inline body contains all four required headings.
# Literal \n values represent the newlines in a JSON-encoded command.
# The hook scans substrings, so the encoding does not affect the result.
body='## Summary\nwhat\n## Motivation\nwhy\n## Changes\n- x\n## Testing\nran zig build test'
# This body omits the Testing section.
missing_testing='## Summary\ns\n## Motivation\nm\n## Changes\n- c'

# payload <command> wraps a Bash command in a PreToolUse envelope.
payload() {
    printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"
}

# assert_exit <description> <expected-status> <payload> compares the hook status.
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

# assert_block_mentions <description> <needle> <payload> examines the block message.
assert_block_mentions() {
    err=$(printf '%s' "$3" | sh "$HOOK" 2>&1 > /dev/null)
    case "$err" in
        *"$2"*) printf 'PASS: %s\n' "$1" ;;
        *) printf 'FAIL: %s (stderr missing: %s)\n' "$1" "$2"
            failures=$((failures + 1)) ;;
    esac
}

# The hook does not change a command that is unrelated to pull requests.
assert_exit 'non-PR command passes' 0 "$(payload 'git status')"

# The hook permits a create command with all four inline headings.
assert_exit 'complete inline body passes' 0 \
    "$(payload "gh pr create --title x --body '$body'")"

# The hook blocks a create command that omits one heading.
# The reason names the omitted heading.
assert_exit 'missing Testing is blocked' 2 \
    "$(payload "gh pr create --title x --body '$missing_testing'")"
assert_block_mentions 'block reason names the missing section' 'Testing' \
    "$(payload "gh pr create --title x --body '$missing_testing'")"

# The hook cannot inspect a body from a file. Thus, it must permit the body.
assert_exit 'body-file fails open' 0 \
    "$(payload 'gh pr create --title x --body-file body.md')"

# gh --fill creates the body. The hook cannot inspect it, so the hook permits it.
assert_exit 'fill fails open' 0 \
    "$(payload 'gh pr create --title x --fill')"

# A create command without a body flag opens the editor. The hook must permit it.
assert_exit 'no body flag fails open' 0 \
    "$(payload 'gh pr create --title x')"

# The hook applies the same rules to body creation and body edits.
assert_exit 'edit with incomplete body is blocked' 2 \
    "$(payload "gh pr edit 12 --body '$missing_testing'")"
assert_block_mentions 'edit block names the missing section' 'Motivation' \
    "$(payload "gh pr edit 12 --body '## Summary\ns\n## Changes\n- c\n## Testing\nt'")"

# If the repository defines a template, the hook enforces that structure.
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
custom_body='## Description\ndetails\n## Checklist\n- [ ] done'
missing_custom='## Description\ndetails'
(
    cd "$template_repo" || exit 1
    assert_exit 'repo template body passes' 0 \
        "$(payload "gh pr create --title x --body '$custom_body'")"
    assert_exit 'repo template missing section is blocked' 2 \
        "$(payload "gh pr create --title x --body '$missing_custom'")"
    assert_block_mentions 'repo template block cites template file' 'pull_request_template.md' \
        "$(payload "gh pr create --title x --body '$missing_custom'")"
)

# The payload `cwd` field identifies the repository that contains the template.
# If its process runs in a different directory, the check must use this field.
# Cursor user hooks run from ~/.cursor. Claude payloads also contain the project directory.
# The temporary process directory is not a Git repository.
# Thus, a template citation proves that the check used the payload field.
cwd_payload() {
    printf '{"cwd":"%s","tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" "$2"
}
elsewhere=$(mktemp -d)
(
    cd "$elsewhere" || exit 1
    assert_exit 'payload cwd selects the template repo' 2 \
        "$(cwd_payload "$template_repo" "gh pr create --title x --body '$missing_custom'")"
    assert_block_mentions 'payload cwd block cites that template' 'pull_request_template.md' \
        "$(cwd_payload "$template_repo" "gh pr create --title x --body '$missing_custom'")"
)
rm -rf "$elsewhere"
rm -rf "$template_repo"

# The hook enforces the exact prefix of each ATX heading level.
h3_repo=$(mktemp -d)
(
    cd "$h3_repo" || exit 1
    git init -q
    git config user.email 'test@example.com'
    git config user.name 'test'
    mkdir -p .github
    printf '%s\n' '### Summary' '### Testing' > .github/pull_request_template.md
    git add .github/pull_request_template.md
    git commit -q -m 'add h3 template'
)
h3_body='### Summary\nwhat\n### Testing\nran tests'
missing_h3='### Summary\nwhat'
(
    cd "$h3_repo" || exit 1
    assert_exit 'h3 template body passes' 0 \
        "$(payload "gh pr create --title x --body '$h3_body'")"
    assert_exit 'h3 template missing section is blocked' 2 \
        "$(payload "gh pr create --title x --body '$missing_h3'")"
)
rm -rf "$h3_repo"

# The hook cannot evaluate a template without ATX headings. Thus, it permits the command.
no_heading_repo=$(mktemp -d)
(
    cd "$no_heading_repo" || exit 1
    git init -q
    git config user.email 'test@example.com'
    git config user.name 'test'
    mkdir -p .github
    printf '%s\n' \
        '<!-- Describe your changes below -->' \
        '- [ ] I added tests' \
        '- [ ] I updated docs' > .github/pull_request_template.md
    git add .github/pull_request_template.md
    git commit -q -m 'add checklist-only template'
)
(
    cd "$no_heading_repo" || exit 1
    assert_exit 'template without headings fails open' 0 \
        "$(payload "gh pr create --title x --body 'no headings here'")"
)
rm -rf "$no_heading_repo"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
