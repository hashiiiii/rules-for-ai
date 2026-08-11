#!/bin/sh
# SessionStart hook for the rules-for-ai plugin (Claude Code).
#
# Injects the always-on rules (AGENTS.md) and the locale keys into the
# session context. The sibling scope resolver uses the first existing
# LOCALE file as a whole:
#   1. <absolute-git-dir>/rules-for-ai/LOCALE.md (local)
#   2. <repo>/.rules-for-ai/LOCALE.md            (project)
#   3. $XDG_CONFIG_HOME/rules-for-ai/LOCALE.md   (user)
#   4. $CLAUDE_PLUGIN_ROOT/LOCALE.default.md     (bundled)
#   5. inline en_US (a resolved block is never empty)
#
# LOCALE files are machine-written by the hashiiiii-locale skill: strict
# key=value lines, always all five keys (issues, pull-requests,
# comments, logs, test-logs), LF endings. The hook trusts that format;
# layers never merge.
# This script must never break session start: it always exits 0.

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

# Always-on rules from the single source of truth.
if [ -f "$PLUGIN_ROOT/AGENTS.md" ]; then
    cat "$PLUGIN_ROOT/AGENTS.md"
else
    printf 'Warning: AGENTS.md not found in plugin; always-on rules were not injected.\n'
fi

printf '\n## Locale (resolved)\n\n'
sh "$HOOK_DIR/resolve-scoped-locale.sh" "$PROJECT_DIR" \
    "$USER_CONFIG" "$PLUGIN_ROOT/LOCALE.default.md"

exit 0
