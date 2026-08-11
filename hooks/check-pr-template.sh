#!/bin/sh
# This script evaluates pull request templates for both hook envelopes.
#
# If an inline body omits a required section, it blocks `gh pr create` and `gh pr edit`.
# If the repository has no template, it requires the default sections:
# Summary, Motivation, Changes, and Testing.
#
# The script reads the complete hook payload from stdin and scans it as text.
# An inline body includes section headings in the JSON-encoded command.
# Thus, a substring scan is sufficient and does not require jq.
# The script cannot read a body from `--body-file`, `-F`, or `--fill`.
# For these body types, the script permits the command.
#
# Exit 0 permits the command. Exit 2 blocks it and writes the reason to stdout.
# The sibling scripts contain the platform envelopes.
# pr-template-check-claude-code.sh uses stderr and exit 2.
# pr-template-check-cursor.sh uses permission JSON.

set -u

input=$(cat)

# Only pull request creation and edits are in scope.
case "$input" in
    *'gh pr create'* | *'gh pr edit'*) ;;
    *) exit 0 ;;
esac

# If the body is not a readable inline literal, permit the command.
# Search for file and fill forms first because --body-file contains --body.
case "$input" in
    *'--body-file'* | *' -F '* | *'--fill'* | *' -f '*) exit 0 ;;
esac

# If an inline body flag is present, enforce the template.
case "$input" in
    *'--body'* | *' -b '*) ;;
    *) exit 0 ;;
esac

# Use the template from the repository that runs the agent command.
# Claude Code, Codex, and Cursor put that repository in the payload `cwd` field.
# The process directory is the fallback because Claude Code runs hooks from the project directory.
# Cursor user hooks run from ~/.cursor. If the payload field is present, use it.
# Machine-written paths use quotes. Therefore, an awk match does not require jq.
payload_cwd=$(printf '%s' "$input" | awk '
    match($0, /"cwd"[[:space:]]*:[[:space:]]*"[^"]*"/) {
        s = substr($0, RSTART, RLENGTH)
        sub(/^"cwd"[[:space:]]*:[[:space:]]*"/, "", s)
        sub(/"$/, "", s)
        print s
        exit
    }')
if [ -n "$payload_cwd" ] && [ -d "$payload_cwd" ]; then
    repo_dir=$payload_cwd
else
    repo_dir=.
fi

find_template_file() {
    root=$(git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null) || return 1

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

# extract_headings writes Markdown ATX headings from the template to stdout.
# A heading line starts with one to six # characters and a space.
# The function intentionally ignores setext headings and non-Markdown structures.
extract_headings() {
    template_file=$1
    grep -E '^#{1,6} [^#]' "$template_file" 2>/dev/null \
        | sed 's/[[:space:]]*$//' \
        | sed '/^$/d'
}

# resolve_headings writes the required headings to stdout.
# Exit 0 means that the function resolved the headings.
# Exit 3 permits the command because the function cannot select or read a template.
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

# Collect the required headings that the body does not contain.
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
    printf 'Pull request body is missing required section(s):%s\n' "$missing"
    printf 'Follow the repository pull request template (%s): include every markdown heading it defines. Rewrite the body and retry.\n' "$template_file"
else
    printf 'Pull request body is missing required section(s):%s\n' "$missing"
    printf 'Follow the hashiiiii-pull-request skill default: the body needs the headings ## Summary, ## Motivation, ## Changes, and ## Testing. Rewrite the body and retry.\n'
fi
exit 2
