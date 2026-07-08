#!/bin/sh
# PreToolUse hook for the rules-for-ai plugin.
#
# Blocks `gh pr create` / `gh pr edit` when the pull request body is set
# inline but is missing one of the sections required by the repository
# pull request template. When the repository has no template, falls back
# to the default sections from the hashiiiii-pull-request skill:
# Summary, Motivation, Changes, Testing.
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

find_template_file() {
    root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1

    for path in \
        "$root/.github/pull_request_template.md" \
        "$root/.github/PULL_REQUEST_TEMPLATE.md" \
        "$root/pull_request_template.md" \
        "$root/docs/pull_request_template.md"
    do
        if [ -f "$path" ]; then
            printf '%s\n' "$path"
            return 0
        fi
    done

    dir="$root/.github/PULL_REQUEST_TEMPLATE"
    if [ -d "$dir" ]; then
        count=$(find "$dir" -maxdepth 1 -name '*.md' -print | wc -l | tr -d ' ')
        case "$count" in
            0) return 1 ;;
            1) find "$dir" -maxdepth 1 -name '*.md' -print | head -n 1
               return 0 ;;
            *) return 2 ;;
        esac
    fi

    return 1
}

# extract_headings writes ATX markdown headings from the template to stdout.
# Lines must start with 1-6 # characters followed by a space; setext headings
# and non-markdown structures are intentionally ignored.
extract_headings() {
    template_file=$1
    grep -E '^#{1,6} [^#]' "$template_file" 2>/dev/null \
        | sed 's/[[:space:]]*$//' \
        | sed '/^$/d'
}

# resolve_headings writes required heading lines to stdout.
# Exit 0: headings resolved. Exit 3: fail open (multiple templates or a
# template with no extractable ATX headings).
resolve_headings() {
    template_file=$(find_template_file)
    status=$?

    case "$status" in
        0)
            headings=$(extract_headings "$template_file")
            if [ -n "$headings" ]; then
                printf '%s\n' "$headings"
                return 0
            fi
            return 3
            ;;
        2) return 3 ;;
    esac

    for heading in '## Summary' '## Motivation' '## Changes' '## Testing'; do
        printf '%s\n' "$heading"
    done
    return 0
}

if ! headings=$(resolve_headings); then
    exit 0
fi

# Collect the required headings that are absent from the body.
missing=''
while IFS= read -r heading; do
    [ -n "$heading" ] || continue
    case "$input" in
        *"$heading"*) ;;
        *) missing="$missing $heading" ;;
    esac
done <<EOF
$headings
EOF

[ -z "$missing" ] && exit 0

template_file=$(find_template_file 2>/dev/null || true)
if [ -n "$template_file" ]; then
    printf 'Pull request body is missing required section(s):%s\n' "$missing" >&2
    printf 'Follow the repository pull request template (%s): include every markdown heading it defines. Rewrite the body and retry.\n' "$template_file" >&2
else
    printf 'Pull request body is missing required section(s):%s\n' "$missing" >&2
    printf 'Follow the hashiiiii-pull-request skill default: the body needs the headings ## Summary, ## Motivation, ## Changes, and ## Testing. Rewrite the body and retry.\n' >&2
fi
exit 2
