#!/bin/sh
# SessionStart hook for the rules-for-ai plugin.
#
# Injects the always-on rules (AGENTS.md) and the resolved locale table
# into the session context. Locale resolution is per row; the first layer
# with a value for an artifact wins:
#   1. $CLAUDE_PROJECT_DIR/LOCALE.md            (project)
#   2. $XDG_CONFIG_HOME/rules-for-ai/LOCALE.md  (user; ~/.config fallback)
#   3. $CLAUDE_PLUGIN_ROOT/LOCALE.default.md    (bundled)
#
# This script must never break session start: it always exits 0.

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
USER_CONFIG="${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md"

PROJECT_LOCALE="$PROJECT_DIR/LOCALE.md"
DEFAULT_LOCALE="$PLUGIN_ROOT/LOCALE.default.md"

# Print "artifact<TAB>language" for every recognized row in a locale
# table. Unknown rows, the header row, and the separator row are ignored.
parse_locale_file() {
    [ -f "$1" ] || return 0
    awk -F'|' '
        NF >= 3 {
            key = $2; val = $3
            gsub(/^[ \t\r]+/, "", key); gsub(/[ \t\r]+$/, "", key)
            gsub(/^[ \t\r]+/, "", val); gsub(/[ \t\r]+$/, "", val)
            if (key != "Issues" && key != "Code comments" && \
                key != "Log messages" && key != "Test log messages") next
            if (val == "" || val == "Language") next
            if (val ~ /^-+$/) next
            print key "\t" val
        }
    ' "$1" 2>/dev/null
}

# Resolve one artifact across the three layers; en_US as the last resort.
resolve_row() {
    artifact="$1"
    for f in "$PROJECT_LOCALE" "$USER_CONFIG" "$DEFAULT_LOCALE"; do
        v=$(parse_locale_file "$f" | awk -F'\t' -v a="$artifact" '$1 == a { print $2; exit }')
        if [ -n "$v" ]; then
            printf '%s' "$v"
            return 0
        fi
    done
    printf 'en_US'
}

# A present-but-unparseable layer is dropped with a warning.
warn_if_unparseable() {
    if [ -f "$1" ] && [ -z "$(parse_locale_file "$1")" ]; then
        printf '\nWarning: %s exists but has no recognizable locale rows; it was ignored.\n' "$2"
    fi
}

# Always-on rules from the single source of truth.
if [ -f "$PLUGIN_ROOT/AGENTS.md" ]; then
    cat "$PLUGIN_ROOT/AGENTS.md"
else
    printf 'Warning: AGENTS.md not found in plugin; always-on rules were not injected.\n'
fi

printf '\n## Locale (resolved)\n\n'
printf '| Artifact | Language |\n'
printf '|----------|----------|\n'
for artifact in 'Issues' 'Code comments' 'Log messages' 'Test log messages'; do
    printf '| %s | %s |\n' "$artifact" "$(resolve_row "$artifact")"
done

warn_if_unparseable "$PROJECT_LOCALE" "project LOCALE.md"
warn_if_unparseable "$USER_CONFIG" "user LOCALE.md"

# Onboarding: the existence of the user-level file means "configured".
if [ ! -f "$USER_CONFIG" ]; then
    printf '\nNo user-level locale preference is set. At the start of this session, ask the user which language to use for each artifact (Issues, Code comments, Log messages, Test log messages) and save the answer with the hashiiiii-locale skill. If the user is happy with the defaults, save the default table unchanged so this prompt never appears again.\n'
fi

exit 0
