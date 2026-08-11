#!/bin/sh
# This script resolves locale scopes for one project directory.
#
# Usage: resolve-scoped-locale.sh <project-dir> <user-file> [default-file ...]
#
# The absolute Git directory keeps local preferences outside the worktree.
# It also gives each linked worktree an independent local file.
set -u

HOOK_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=${1:-}
USER_CONFIG=${2:-}
[ "$#" -gt 0 ] && shift
[ "$#" -gt 0 ] && shift

if [ -n "$PROJECT_DIR" ] \
    && REPO_ROOT=$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2> /dev/null) \
    && GIT_DIR=$(git -C "$PROJECT_DIR" rev-parse --absolute-git-dir 2> /dev/null); then
    set -- "$GIT_DIR/rules-for-ai/LOCALE.md" \
        "$REPO_ROOT/.rules-for-ai/LOCALE.md" "$USER_CONFIG" "$@"
else
    set -- "$USER_CONFIG" "$@"
fi

sh "$HOOK_DIR/resolve-locale.sh" "$@"
