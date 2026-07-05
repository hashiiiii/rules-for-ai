#!/bin/sh
# SessionStart hook for the rules-for-ai plugin.
#
# Injects the always-on rules (AGENTS.md) and the locale keys into the
# session context. The first existing LOCALE file wins as a whole:
#   1. $CLAUDE_PROJECT_DIR/LOCALE.md            (project)
#   2. $XDG_CONFIG_HOME/rules-for-ai/LOCALE.md  (user; ~/.config fallback)
#   3. $CLAUDE_PLUGIN_ROOT/LOCALE.default.md    (bundled)
#
# LOCALE files are machine-written by the hashiiiii-locale skill: strict
# key=value lines, always all four keys (issues, comments, logs,
# test-logs), LF endings. The hook trusts that format; layers never merge.
# This script must never break session start: it always exits 0.

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
USER_CONFIG="${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md"

# Always-on rules from the single source of truth.
if [ -f "$PLUGIN_ROOT/AGENTS.md" ]; then
    cat "$PLUGIN_ROOT/AGENTS.md"
else
    printf 'Warning: AGENTS.md not found in plugin; always-on rules were not injected.\n'
fi

locale_file=''
for f in "$PROJECT_DIR/LOCALE.md" "$USER_CONFIG" "$PLUGIN_ROOT/LOCALE.default.md"; do
    if [ -f "$f" ]; then
        locale_file=$f
        break
    fi
done

if [ -n "$locale_file" ]; then
    printf '\n## Locale (resolved)\n\n'
    grep -E '^(issues|comments|logs|test-logs)=' "$locale_file"
fi

# Onboarding: the existence of the user-level file means "configured".
if [ ! -f "$USER_CONFIG" ]; then
    printf '\nNo user-level locale preference is set. At the start of this session, ask the user which language to use for each artifact (Issues, Code comments, Log messages, Test log messages) and save the answer with the hashiiiii-locale skill. If the user is happy with the defaults, save the default file unchanged so this prompt never appears again.\n'
fi

exit 0
