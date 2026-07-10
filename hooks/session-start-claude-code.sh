#!/bin/sh
# SessionStart hook for the rules-for-ai plugin (Claude Code).
#
# Injects the always-on rules (AGENTS.md) and the locale keys into the
# session context. Resolution lives in the sibling resolve-locale.sh;
# the first existing LOCALE file wins as a whole:
#   1. $XDG_CONFIG_HOME/rules-for-ai/LOCALE.md  (user; ~/.config fallback)
#   2. $CLAUDE_PLUGIN_ROOT/LOCALE.default.md    (bundled)
#   3. inline en_US (resolver fallback; a resolved block is never empty)
#
# There is deliberately no project-level layer: a project-root LOCALE.md
# is ignored. Project language policy lives in the project's own
# CLAUDE.md / AGENTS.md and overrides these keys.
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

# Always-on rules from the single source of truth.
if [ -f "$PLUGIN_ROOT/AGENTS.md" ]; then
    cat "$PLUGIN_ROOT/AGENTS.md"
else
    printf 'Warning: AGENTS.md not found in plugin; always-on rules were not injected.\n'
fi

printf '\n## Locale (resolved)\n\n'
sh "$HOOK_DIR/resolve-locale.sh" "$USER_CONFIG" "$PLUGIN_ROOT/LOCALE.default.md"

exit 0
