#!/bin/sh
# This PreToolUse hook supports the rules-for-ai plugin in Claude Code and Codex.
#
# This script is an envelope for the shared check-pr-template.sh script.
# The shared script reads the PreToolUse payload from stdin.
# Exit 0 permits the command. Exit 2 blocks it and writes the reason to stderr.
# This behavior implements the shared Claude Code and Codex block contract.
# Any other status permits the command because the shared script cannot evaluate it.
set -u

HOOK_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

reason=$(sh "$HOOK_DIR/check-pr-template.sh")
status=$?

[ "$status" -ne 2 ] && exit 0
printf '%s\n' "$reason" >&2
exit 2
