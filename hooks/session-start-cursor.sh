#!/bin/sh
# sessionStart hook for Cursor project/local installs.
#
# Emits {"additional_context": ...} on stdout; Cursor injects that text
# into the model context. The always-on rules already ride on
# .cursor/rules/agents.mdc (alwaysApply), so this hook injects only the
# resolved locale keys. The first existing LOCALE file wins as a whole:
#   1. $XDG_CONFIG_HOME/rules-for-ai/LOCALE.md  (user; ~/.config fallback)
#   2. inline en_US via resolve-locale.sh (project installs carry no
#      bundled LOCALE.default.md)
#
# The installer copies this script and its sibling resolve-locale.sh
# into <repo>/.cursor/rules-for-ai/, so it must stay self-contained:
# absolute env paths plus a dirname "$0" sibling lookup, no plugin
# root, no jq.
# This script must never break session start: it always exits 0.

set -u

HOOK_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
USER_CONFIG="${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md"

# Consume the hook input JSON on stdin; only the output contract matters.
cat > /dev/null 2>&1

# JSON string escaper without jq: sed doubles backslashes and escapes
# double quotes, awk joins lines with a literal \n. LOCALE values are
# machine-written key=value lines, so other control characters do not
# occur.
json_escape() {
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' \
        | awk 'BEGIN { ORS = "" } NR > 1 { print "\\n" } { print }'
}

escaped=$(
    {
        printf '## Locale (resolved)\n\n'
        sh "$HOOK_DIR/resolve-locale.sh" "$USER_CONFIG"
    } | json_escape
)

printf '{"additional_context":"%s"}\n' "$escaped"
exit 0
