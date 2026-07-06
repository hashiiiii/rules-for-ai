#!/bin/sh
# install.sh -- install, update, or uninstall rules-for-ai for Claude
# Code and Cursor at user, project, or local scope.
#
# Usage:
#   ./install.sh [--uninstall] <claude|cursor> <user|project|local> [target-dir]
#
# Scopes:
#   user     every project on this machine
#   project  the target repo, shared with the team via git
#   local    the target repo, this machine only (nothing committed)
#
# target-dir applies to project/local scopes only and defaults to the
# current directory. It must be a git repository and must not be the
# rules-for-ai repo itself.
#
# curl mode: when this script does not sit inside its repo (e.g. piped
# from curl), it clones RULES_FOR_AI_SOURCE (default: REPO below) into
# a temp dir, installs from that copy, and removes it on exit.
#
# Re-running an install is the update path for every cell. Uninstall
# removes only what install created.
# shellcheck disable=SC2034,SC2329  # skeleton: used once all cells land
set -u

# Forks: point this at your fork (see README, Fork and customize).
REPO="https://github.com/hashiiiii/rules-for-ai"

# The locale skill writes user-level config (~/.config/rules-for-ai),
# so project-closed cells exclude it; language policy belongs in the
# target project's own instructions.
LOCALE_SKILL="hashiiiii-locale"

usage() {
    printf 'usage: %s [--uninstall] <claude|cursor> <user|project|local> [target-dir]\n' "$0" >&2
    exit 1
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" > /dev/null 2>&1 || die "'$1' is required but not on PATH"
}

# --- argument parsing --------------------------------------------------

MODE=install
if [ "${1:-}" = "--uninstall" ]; then
    MODE=uninstall
    shift
fi
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    usage
fi
PLATFORM=$1
SCOPE=$2
TARGET=${3:-.}

case "$PLATFORM" in
    claude|cursor) ;;
    *) usage ;;
esac
case "$SCOPE" in
    user) [ $# -eq 2 ] || die 'target-dir does not apply to user scope' ;;
    project|local) ;;
    *) usage ;;
esac

# --- source repo resolution ---------------------------------------------

SOURCE=${RULES_FOR_AI_SOURCE:-$REPO}

# The repo is either around this script (checkout mode) or a temp clone
# of SOURCE (curl mode). Two markers guard against mistaking an
# unrelated plugin repo for ours.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" 2> /dev/null && pwd) || SCRIPT_DIR=''
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/.claude-plugin/plugin.json" ] \
    && [ -f "$SCRIPT_DIR/rules/agents.mdc" ]; then
    ROOT=$SCRIPT_DIR
else
    die 'not implemented'
fi

# First "name" value in a machine-written manifest. Not a JSON parser;
# both manifests keep their own name as the first name key.
json_name() {
    sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n 1
}

PLUGIN=$(json_name "$ROOT/.claude-plugin/plugin.json")
MARKETPLACE=$(json_name "$ROOT/.claude-plugin/marketplace.json")
if [ -z "$PLUGIN" ] || [ -z "$MARKETPLACE" ]; then
    die 'could not derive names from plugin manifests'
fi

# --- shared helpers -------------------------------------------------------

resolve_target() {
    [ -d "$TARGET" ] || die "target directory not found: $TARGET"
    TARGET=$(CDPATH='' cd -- "$TARGET" && pwd)
    [ "$TARGET" = "$ROOT" ] && die 'target is the rules-for-ai repo itself'
    git -C "$TARGET" rev-parse --git-dir > /dev/null 2>&1 \
        || die "target is not a git repository: $TARGET"
}

# Relative paths installed into a target repo by the cursor cells.
managed_paths() {
    printf '.cursor/rules/agents.mdc\n'
    for skill_dir in "$ROOT"/skills/*/; do
        skill=$(basename "$skill_dir")
        [ "$skill" = "$LOCALE_SKILL" ] && continue
        printf '.cursor/skills/%s\n' "$skill"
    done
}

# --- cells -----------------------------------------------------------------

claude_install() { die 'not implemented'; }
claude_uninstall() { die 'not implemented'; }
cursor_user_install() { die 'not implemented'; }
cursor_user_uninstall() { die 'not implemented'; }
cursor_project_install() { die 'not implemented'; }
cursor_project_uninstall() { die 'not implemented'; }

# --- dispatch --------------------------------------------------------------

if [ "$PLATFORM" = claude ]; then
    [ "$SCOPE" = user ] || resolve_target
    if [ "$MODE" = install ]; then claude_install; else claude_uninstall; fi
else
    if [ "$SCOPE" = user ]; then
        if [ "$MODE" = install ]; then cursor_user_install; else cursor_user_uninstall; fi
    else
        resolve_target
        if [ "$MODE" = install ]; then cursor_project_install; else cursor_project_uninstall; fi
    fi
fi
