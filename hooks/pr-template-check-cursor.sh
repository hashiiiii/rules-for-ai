#!/bin/sh
# beforeShellExecution hook for Cursor installs.
#
# Thin envelope over the shared check-pr-template.sh, which reads the
# hook payload on stdin and decides. Emits {"permission":"allow"} to
# let the command run, or {"permission":"deny","agent_message":...}
# with the reason so the agent rewrites the pull request body. Any core
# status other than the block code fails open, and the wrapper always
# exits 0: this hook must never break a shell command it could not
# actually judge.
#
# The installer copies this script and its siblings check-pr-template.sh
# and json-escape.sh into <repo>/.cursor/rules-for-ai/, so it must stay
# self-contained: dirname "$0" sibling lookups only, no jq.
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
