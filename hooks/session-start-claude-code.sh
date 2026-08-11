#!/bin/sh
# This SessionStart hook supports the rules-for-ai plugin in Claude Code.
#
# It adds the always-on rules and locale keys to the session context.
# The sibling scope resolver uses the first existing LOCALE file:
#   1. <absolute-git-dir>/rules-for-ai/LOCALE.md (local)
#   2. <repo>/.rules-for-ai/LOCALE.md            (project)
#   3. $XDG_CONFIG_HOME/rules-for-ai/LOCALE.md   (user)
#   4. $CLAUDE_PLUGIN_ROOT/LOCALE.default.md     (bundled)
#   5. inline en_US values
#
# The hashiiiii-locale skill writes LOCALE files.
# These files contain all five keys as strict key=value lines with LF endings.
# The keys are issues, pull-requests, comments, logs, and test-logs.
# The hook trusts this format. The locale layers do not merge.
# This script always exits 0 because it must not stop session start.

set -u

HOOK_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
USER_CONFIG="${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md"
HOOK_INPUT=$(cat 2> /dev/null) || HOOK_INPUT=''

PROJECT_DIR=$(printf '%s' "$HOOK_INPUT" | awk '
    match($0, /"cwd"[[:space:]]*:[[:space:]]*"[^"]*"/) {
        value = substr($0, RSTART, RLENGTH)
        sub(/^"cwd"[[:space:]]*:[[:space:]]*"/, "", value)
        sub(/"$/, "", value)
        print value
        exit
    }
')
if [ ! -d "$PROJECT_DIR" ]; then
    PROJECT_DIR=${CLAUDE_PROJECT_DIR:-}
fi

# Read the always-on rules from their single source.
if [ -f "$PLUGIN_ROOT/AGENTS.md" ]; then
    cat "$PLUGIN_ROOT/AGENTS.md"
else
    printf 'Warning: AGENTS.md not found in plugin; always-on rules were not injected.\n'
fi

printf '\n## Locale (resolved)\n\n'
sh "$HOOK_DIR/resolve-scoped-locale.sh" "$PROJECT_DIR" \
    "$USER_CONFIG" "$PLUGIN_ROOT/LOCALE.default.md"

exit 0
