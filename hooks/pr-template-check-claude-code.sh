#!/bin/sh
# PreToolUse hook for the rules-for-ai plugin (Claude Code).
#
# Thin envelope over the shared check-pr-template.sh, which reads the
# PreToolUse payload on stdin and decides. Exit 0 lets the command run.
# Exit 2 blocks it and feeds the reason back to the agent on stderr —
# Claude Code's block contract. Any other core status fails open: the
# check must never block a command it could not actually judge.
set -u

HOOK_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

reason=$(sh "$HOOK_DIR/check-pr-template.sh")
status=$?

[ "$status" -ne 2 ] && exit 0
printf '%s\n' "$reason" >&2
exit 2
