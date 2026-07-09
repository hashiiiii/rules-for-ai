#!/bin/sh
# rules-for-ai.sh -- install, update, or uninstall rules-for-ai for Claude
# Code and Cursor at user, project, or local scope.
#
# Usage:
#   ./rules-for-ai.sh <install|uninstall> <claude|cursor> <user|project|local> [target-dir]
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
set -u

# Forks: point this at your fork (see README, Fork and customize).
REPO="https://github.com/hashiiiii/rules-for-ai"

# The locale skill writes user-level config (~/.config/rules-for-ai),
# so project-closed cells exclude it; language policy belongs in the
# target project's own instructions.
LOCALE_SKILL="hashiiiii-locale"

usage() {
    # "help" prints to stdout and exits 0 (explicit request); anything
    # else is the error path: stderr and exit 1.
    _u="usage: $0 <install|uninstall> <claude|cursor> <user|project|local> [target-dir]"
    if [ "${1:-}" = help ]; then
        printf '%s\n' "$_u"
        exit 0
    fi
    printf '%s\n' "$_u" >&2
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

case "${1:-}" in
    install|uninstall) ACTION=$1; shift ;;
    -h|--help|help) usage help ;;
    *) usage ;;
esac
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
    require_cmd git
    ROOT=$(mktemp -d)
    trap 'rm -rf "$ROOT"' EXIT
    git clone --quiet --depth 1 "$SOURCE" "$ROOT" || die "could not clone $SOURCE"
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
# .cursor/hooks.json is deliberately NOT listed: it is only ours when
# byte-identical to cursor_hooks_json (see hooks_json_owned).
managed_paths() {
    printf '.cursor/rules/agents.mdc\n'
    printf '.cursor/rules-for-ai/resolve-locale.sh\n'
    printf '.cursor/rules-for-ai/session-start-cursor.sh\n'
    for skill_dir in "$ROOT"/skills/*/; do
        skill=$(basename "$skill_dir")
        [ "$skill" = "$LOCALE_SKILL" ] && continue
        printf '.cursor/skills/%s\n' "$skill"
    done
}

# --- cells -----------------------------------------------------------------

claude_run_dir() {
    if [ "$SCOPE" = user ]; then printf '.'; else printf '%s' "$TARGET"; fi
}

claude_install() {
    require_cmd claude
    run_dir=$(claude_run_dir)
    (
        CDPATH='' cd -- "$run_dir" || exit 1
        claude plugin marketplace add "$SOURCE" --scope "$SCOPE" \
            && claude plugin marketplace update "$MARKETPLACE" \
            && claude plugin install "$PLUGIN@$MARKETPLACE" --scope "$SCOPE"
    ) || die 'claude plugin command failed'
    printf 'installed %s@%s (%s scope)\n' "$PLUGIN" "$MARKETPLACE" "$SCOPE"
}

claude_uninstall() {
    require_cmd claude
    run_dir=$(claude_run_dir)
    (
        CDPATH='' cd -- "$run_dir" || exit 1
        claude plugin uninstall "$PLUGIN@$MARKETPLACE" --scope "$SCOPE"
    ) || die 'claude plugin uninstall failed'
    printf "uninstalled %s@%s (%s scope); run 'claude plugin marketplace remove %s' if nothing else uses the marketplace\n" \
        "$PLUGIN" "$MARKETPLACE" "$SCOPE" "$MARKETPLACE"
}
cursor_user_dest() {
    printf '%s/.cursor/plugins/local/%s' "$HOME" "$PLUGIN"
}

cursor_user_install() {
    require_cmd git
    dest=$(cursor_user_dest)
    if [ -d "$dest/.git" ]; then
        git -C "$dest" pull --ff-only --quiet || die "update failed in $dest"
    else
        mkdir -p "$(dirname -- "$dest")"
        git clone --quiet "$SOURCE" "$dest" || die "could not clone $SOURCE"
    fi
    # Cursor also imports plugins enabled for Claude Code from
    # ~/.claude/plugins; a second copy here would double-load.
    if grep -qs "\"$PLUGIN@" "$HOME/.claude/settings.json"; then
        printf 'warning: %s is also enabled for Claude Code; Cursor may import it from ~/.claude/plugins as well\n' "$PLUGIN" >&2
    fi
    printf 'installed to %s -- restart Cursor to load it\n' "$dest"
}

cursor_user_uninstall() {
    dest=$(cursor_user_dest)
    rm -rf "$dest"
    printf 'removed %s -- restart Cursor to unload it\n' "$dest"
}
exclude_file() {
    printf '%s/info/exclude' "$(git -C "$TARGET" rev-parse --absolute-git-dir)"
}

# Canonical .cursor/hooks.json written when the target has none. The
# command is relative because Cursor runs sessionStart hooks with
# cwd = project root (verified 2026-07-10 via a cursor-agent spike).
cursor_hooks_json() {
    cat <<'EOF'
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      { "command": "sh .cursor/rules-for-ai/session-start-cursor.sh" }
    ]
  }
}
EOF
}

# True when the target's hooks.json is byte-identical to ours, i.e. we
# created it and may overwrite or remove it.
hooks_json_owned() {
    cursor_hooks_json | cmp -s - "$TARGET/.cursor/hooks.json" 2> /dev/null
}

cursor_project_install() {
    mkdir -p "$TARGET/.cursor/rules" "$TARGET/.cursor/skills"
    cp "$ROOT/rules/agents.mdc" "$TARGET/.cursor/rules/agents.mdc"
    for skill_dir in "$ROOT"/skills/*/; do
        skill=$(basename "$skill_dir")
        [ "$skill" = "$LOCALE_SKILL" ] && continue
        rm -rf "${TARGET:?}/.cursor/skills/$skill"
        cp -R "${skill_dir%/}" "$TARGET/.cursor/skills/$skill"
    done
    mkdir -p "$TARGET/.cursor/rules-for-ai"
    cp "$ROOT/hooks/resolve-locale.sh" "$TARGET/.cursor/rules-for-ai/resolve-locale.sh"
    cp "$ROOT/hooks/session-start-cursor.sh" "$TARGET/.cursor/rules-for-ai/session-start-cursor.sh"
    # hooks.json is wholesale-or-warn: write it only when absent or
    # already ours; never merge into someone else's file (no jq).
    if [ -f "$TARGET/.cursor/hooks.json" ] && ! hooks_json_owned; then
        printf 'warning: %s/.cursor/hooks.json already exists; add this sessionStart entry manually:\n' "$TARGET" >&2
        printf '  { "command": "sh .cursor/rules-for-ai/session-start-cursor.sh" }\n' >&2
    else
        cursor_hooks_json > "$TARGET/.cursor/hooks.json"
    fi
    if [ "$SCOPE" = local ]; then
        exclude=$(exclude_file)
        mkdir -p "$(dirname -- "$exclude")"
        [ -f "$exclude" ] || : > "$exclude"
        managed_paths | while IFS= read -r path; do
            if git -C "$TARGET" ls-files --error-unmatch "$path" > /dev/null 2>&1; then
                printf 'warning: %s is already tracked; local scope cannot hide it -- use project scope\n' "$path" >&2
            fi
            grep -qxF "$path" "$exclude" || printf '%s\n' "$path" >> "$exclude"
        done
    fi
    printf 'installed cursor files into %s (%s scope)\n' "$TARGET" "$SCOPE"
}

cursor_project_uninstall() {
    # Ownership must be decided before anything is removed.
    if hooks_json_owned; then owned_hooks=1; else owned_hooks=0; fi
    managed_paths | while IFS= read -r path; do
        rm -rf "${TARGET:?}/$path"
    done
    if [ "$owned_hooks" = 1 ]; then
        rm -f "$TARGET/.cursor/hooks.json"
    fi
    if [ "$SCOPE" = local ]; then
        exclude=$(exclude_file)
        if [ -f "$exclude" ]; then
            patterns=$(mktemp)
            kept=$(mktemp)
            managed_paths > "$patterns"
            grep -vxF -f "$patterns" "$exclude" > "$kept" || :
            mv "$kept" "$exclude"
            rm -f "$patterns"
        fi
    fi
    rmdir "$TARGET/.cursor/skills" "$TARGET/.cursor/rules-for-ai" "$TARGET/.cursor/rules" "$TARGET/.cursor" 2> /dev/null || :
    printf 'removed cursor files from %s (%s scope)\n' "$TARGET" "$SCOPE"
}

# --- dispatch --------------------------------------------------------------

if [ "$PLATFORM" = claude ]; then
    [ "$SCOPE" = user ] || resolve_target
    if [ "$ACTION" = install ]; then claude_install; else claude_uninstall; fi
else
    if [ "$SCOPE" = user ]; then
        if [ "$ACTION" = install ]; then cursor_user_install; else cursor_user_uninstall; fi
    else
        resolve_target
        if [ "$ACTION" = install ]; then cursor_project_install; else cursor_project_uninstall; fi
    fi
fi
