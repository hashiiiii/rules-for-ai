#!/bin/sh
# sessionStart hook for Cursor installs (every scope).
#
# Emits {"additional_context": ...} on stdout; Cursor injects that text
# into the model context. The always-on rules already ride on
# agents.mdc (alwaysApply), so this hook injects only the resolved
# locale keys. The first existing LOCALE file wins as a whole:
#   1. $XDG_CONFIG_HOME/rules-for-ai/LOCALE.md  (user; ~/.config fallback)
#   2. LOCALE.default.md next to this script    (project/local install
#      copy in .cursor/rules-for-ai/)
#   3. LOCALE.default.md one level up           (user-scope plugin clone,
#      where this script lives in <clone>/hooks/)
#   4. inline en_US via resolve-locale.sh (a resolved block is never
#      empty)
#
# The installer copies this script and its siblings resolve-locale.sh /
# json-escape.sh / LOCALE.default.md into <repo>/.cursor/rules-for-ai/,
# so it must stay self-contained: absolute env paths plus dirname "$0"
# sibling lookups, no plugin root, no jq.
# This script must never break session start: it always exits 0.

set -u

HOOK_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
USER_CONFIG="${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md"

# Consume the hook input JSON on stdin; only the output contract matters.
cat > /dev/null 2>&1

escaped=$(
    {
        printf '## Locale (resolved)\n\n'
        sh "$HOOK_DIR/resolve-locale.sh" "$USER_CONFIG" \
            "$HOOK_DIR/LOCALE.default.md" "$HOOK_DIR/../LOCALE.default.md"
    } | sh "$HOOK_DIR/json-escape.sh"
)

printf '{"additional_context":"%s"}\n' "$escaped"
exit 0
