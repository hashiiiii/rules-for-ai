#!/bin/sh
# This beforeShellExecution hook supports Cursor installations.
#
# This script is an envelope for the shared check-pr-template.sh script.
# The shared script reads the hook payload from stdin.
# The envelope emits {"permission":"allow"} to permit the command.
# It emits {"permission":"deny","agent_message":...} to block the command.
# The message tells the agent why it must rewrite the pull request body.
# A status other than the block code permits the command.
# The envelope always exits 0 because it must not stop an unevaluated command.
#
# The installer copies this script and its sibling scripts into <repo>/.cursor/rules-for-ai/.
# Thus, use only dirname "$0" sibling lookups. Do not use jq.
set -u

HOOK_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

reason=$(sh "$HOOK_DIR/check-pr-template.sh")
status=$?

if [ "$status" -ne 2 ]; then
    printf '{"permission":"allow"}\n'
    exit 0
fi

escaped=$(printf '%s' "$reason" | sh "$HOOK_DIR/json-escape.sh")
printf '{"permission":"deny","agent_message":"%s"}\n' "$escaped"
exit 0
