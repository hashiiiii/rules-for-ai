#!/bin/sh
# This sessionStart hook supports Cursor installations at every scope.
#
# It emits {"additional_context": ...} to stdout.
# Cursor adds this text to the model context.
# The always-on rules use agents.mdc with alwaysApply.
# Thus, this hook adds only the resolved locale keys.
# The first existing LOCALE file wins as a whole:
#   1. <absolute-git-dir>/rules-for-ai/LOCALE.md (local)
#   2. <repo>/.rules-for-ai/LOCALE.md            (project)
#   3. $XDG_CONFIG_HOME/rules-for-ai/LOCALE.md   (user)
#   4. LOCALE.default.md next to this script (project or local copy)
#   5. LOCALE.default.md one level up (user plugin clone)
#   6. inline en_US values from resolve-locale.sh
#
# The installer copies this script and its support files into .cursor/rules-for-ai/.
# Thus, use absolute environment paths and dirname "$0" sibling lookups.
# Do not use the plugin root or jq.
# This script always exits 0 because it must not stop session start.

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

# A copied project hook can find its repository without input from older Cursor versions.
# A user hook cannot use this directory structure.
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
