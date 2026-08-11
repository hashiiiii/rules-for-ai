#!/bin/sh
# sessionStart hook for Cursor installs (every scope).
#
# Emits {"additional_context": ...} on stdout; Cursor injects that text
# into the model context. The always-on rules already ride on
# agents.mdc (alwaysApply), so this hook injects only the resolved
# locale keys. The first existing LOCALE file wins as a whole:
#   1. <absolute-git-dir>/rules-for-ai/LOCALE.md (local)
#   2. <repo>/.rules-for-ai/LOCALE.md            (project)
#   3. $XDG_CONFIG_HOME/rules-for-ai/LOCALE.md   (user)
#   4. LOCALE.default.md next to this script    (project/local install
#      copy in .cursor/rules-for-ai/)
#   5. LOCALE.default.md one level up           (user-scope plugin clone,
#      where this script lives in <clone>/hooks/)
#   6. inline en_US via resolve-locale.sh (a resolved block is never
#      empty)
#
# The installer copies this script and its sibling scope resolver,
# locale resolver, JSON escaper, and default into .cursor/rules-for-ai/.
# so it must stay self-contained: absolute env paths plus dirname "$0"
# sibling lookups, no plugin root, no jq.
# This script must never break session start: it always exits 0.

set -u

HOOK_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
USER_CONFIG="${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md"

HOOK_INPUT=$(cat 2> /dev/null) || HOOK_INPUT=''
PROJECT_DIR=$(printf '%s' "$HOOK_INPUT" | awk '
    match($0, /"workspace_roots"[[:space:]]*:[[:space:]]*\[[[:space:]]*"[^"]*"/) {
        value = substr($0, RSTART, RLENGTH)
        sub(/^"workspace_roots"[[:space:]]*:[[:space:]]*\[[[:space:]]*"/, "", value)
        sub(/"$/, "", value)
        print value
        exit
    }
')

# A copied project hook can find its repository without input from
# older Cursor versions. A user hook cannot use this directory shape.
if [ ! -d "$PROJECT_DIR" ]; then
    case "$HOOK_DIR" in
        */.cursor/rules-for-ai)
            PROJECT_DIR=$(CDPATH='' cd -- "$HOOK_DIR/../.." && pwd)
            ;;
        *) PROJECT_DIR='' ;;
    esac
fi

escaped=$(
    {
        printf '## Locale (resolved)\n\n'
        sh "$HOOK_DIR/resolve-scoped-locale.sh" "$PROJECT_DIR" "$USER_CONFIG" \
            "$HOOK_DIR/LOCALE.default.md" "$HOOK_DIR/../LOCALE.default.md"
    } | sh "$HOOK_DIR/json-escape.sh"
)

printf '{"additional_context":"%s"}\n' "$escaped"
exit 0
