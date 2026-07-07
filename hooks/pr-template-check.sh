#!/bin/sh
# PreToolUse hook for the rules-for-ai plugin.
#
# Blocks `gh pr create` / `gh pr edit` when the pull request body is set
# inline but is missing one of the sections the hashiiiii-pull-request
# skill requires: Summary, Motivation, Changes, Testing.
#
# The hook reads the PreToolUse payload from stdin and scans the Bash
# command. An inline body (--body / -b, heredoc included) carries the
# section headings as literal text, so a substring scan is enough and
# needs no jq. A body read from a file (--body-file / -F) or built by gh
# (--fill) is invisible here, so the hook fails OPEN in those cases: it
# never blocks a body it cannot actually read.
#
# Exit 0 lets the command run. Exit 2 blocks it and feeds stderr back to
# the agent as the reason to rewrite the body.

set -u

# The whole payload is enough: an inline body carries its headings as
# literal text inside the JSON-encoded command, robust to shell quoting.
input=$(cat)

# Only pull request creation/edit is in scope.
case "$input" in
    *'gh pr create'* | *'gh pr edit'*) ;;
    *) exit 0 ;;
esac

# Fail open when the body is not an inline literal we can read. Check the
# file/fill forms before --body, since --body-file also contains --body.
case "$input" in
    *'--body-file'* | *' -F '* | *'--fill'* | *' -f '*) exit 0 ;;
esac

# Enforce only when an inline body flag is actually present.
case "$input" in
    *'--body'* | *' -b '*) ;;
    *) exit 0 ;;
esac

# Collect the required sections that are absent from the body.
missing=''
for section in Summary Motivation Changes Testing; do
    case "$input" in
        *"## $section"*) ;;
        *) missing="$missing $section" ;;
    esac
done

[ -z "$missing" ] && exit 0

printf 'Pull request body is missing required section(s):%s\n' "$missing" >&2
printf 'Follow the hashiiiii-pull-request skill: the body needs the headings ## Summary, ## Motivation, ## Changes, and ## Testing. Rewrite the body and retry.\n' >&2
exit 2
