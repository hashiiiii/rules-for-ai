#!/bin/sh
# rules-for-ai.sh installs, updates, or removes rules-for-ai.
# It supports Claude Code, Codex, and Cursor at user, project, or local scope.
#
# Usage:
#   ./rules-for-ai.sh <install|uninstall> <claude|codex|cursor> <user|project|local> [target-dir]
#
# Scopes:
#   user     all projects on this machine
#   project  the target repository, shared with the team through Git
#   local    the target repository on this machine, without committed files
#
# target-dir applies only to project and local scopes.
# Its default value is the current directory.
# It must be a Git repository, but it must not be the rules-for-ai repository.
#
# In curl mode, this script is outside its repository.
# The script clones RULES_FOR_AI_SOURCE into a temporary directory.
# REPO below supplies the default source.
# The script installs from the clone and removes it before exit.
#
# Run install again to update each cell.
# Uninstall removes only the files that install created.
set -u

# For a fork, set this value to the fork URL. See Fork and customize in README.md.
REPO="https://github.com/hashiiiii/rules-for-ai"

# Cursor project and local cells copy these hook scripts into the target repository.
# One list keeps the copy, exclusion, and uninstall operations synchronized.
CURSOR_SUPPORT_FILES='resolve-locale.sh resolve-scoped-locale.sh session-start-cursor.sh json-escape.sh check-pr-template.sh pr-template-check-cursor.sh'

usage() {
    # An explicit help request writes to stdout and exits 0.
    # All other calls use the error path, stderr, and exit 1.
    _u="usage: $0 <install|uninstall> <claude|codex|cursor> <user|project|local> [target-dir]"
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
    claude|codex|cursor) ;;
    *) usage ;;
esac
case "$SCOPE" in
    user) [ $# -eq 2 ] || die 'target-dir does not apply to user scope' ;;
    project|local) ;;
    *) usage ;;
esac

# --- source repository resolution ---------------------------------------

SOURCE=${RULES_FOR_AI_SOURCE:-$REPO}

# In checkout mode, the repository contains this script.
# In curl mode, the repository is a temporary clone of SOURCE.
# Two marker files prevent selection of an unrelated plugin repository.
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

# Both machine-written manifests put their own name in the first name key.
# Thus, this function does not require a JSON parser.
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

# Cursor cells install these relative paths into a target repository.
# This list intentionally omits .cursor/hooks.json.
# If that file matches cursor_hooks_json, it belongs to this installer.
managed_paths() {
    printf '.cursor/rules/agents.mdc\n'
    for file in $CURSOR_SUPPORT_FILES; do
        printf '.cursor/rules-for-ai/%s\n' "$file"
    done
    printf '.cursor/rules-for-ai/LOCALE.default.md\n'
    for skill_dir in "$ROOT"/skills/*/; do
        printf '.cursor/skills/%s\n' "$(basename "$skill_dir")"
    done
}

# The ownership copy records the exact rule that the installer last wrote.
# Thus, an update or removal does not overwrite a rule that the user changed.
install_owned_rule() {
    rule=$1
    ownership_copy=$2
    mkdir -p "$(dirname -- "$rule")" "$(dirname -- "$ownership_copy")"
    if [ ! -e "$rule" ]; then
        cp "$ROOT/AGENTS.md" "$rule"
        cp "$ROOT/AGENTS.md" "$ownership_copy"
    elif [ -f "$ownership_copy" ] && cmp -s "$rule" "$ownership_copy"; then
        cp "$ROOT/AGENTS.md" "$rule"
        cp "$ROOT/AGENTS.md" "$ownership_copy"
    else
        printf 'warning: %s already exists; merge rules from %s manually\n' \
            "$rule" "$ROOT/AGENTS.md" >&2
    fi
}

skill_directories_match() {
    [ -d "$1" ] && [ -d "$2" ] && diff -qr "$1" "$2" > /dev/null 2>&1
}

install_owned_skills() {
    destination=$1
    ownership_root=$2
    mkdir -p "$destination" "$ownership_root"
    for skill_dir in "$ROOT"/skills/*/; do
        skill=$(basename "$skill_dir")
        installed="$destination/$skill"
        ownership_copy="$ownership_root/$skill"
        if [ ! -e "$installed" ]; then
            cp -R "${skill_dir%/}" "$installed"
            cp -R "${skill_dir%/}" "$ownership_copy"
        elif skill_directories_match "$installed" "$ownership_copy"; then
            rm -rf "$installed" "$ownership_copy"
            cp -R "${skill_dir%/}" "$installed"
            cp -R "${skill_dir%/}" "$ownership_copy"
        else
            printf 'warning: %s already exists; the installer did not replace it\n' "$installed" >&2
        fi
    done
}

remove_owned_skills() {
    destination=$1
    ownership_root=$2
    for skill_dir in "$ROOT"/skills/*/; do
        skill=$(basename "$skill_dir")
        installed="$destination/$skill"
        ownership_copy="$ownership_root/$skill"
        if [ -d "$ownership_copy" ]; then
            if skill_directories_match "$installed" "$ownership_copy"; then
                rm -rf "$installed"
            elif [ -e "$installed" ]; then
                printf 'warning: %s was modified; the installer did not remove it\n' "$installed" >&2
            fi
            rm -rf "$ownership_copy"
        fi
    done
}

remove_owned_rule() {
    rule=$1
    ownership_copy=$2
    if [ -f "$ownership_copy" ]; then
        if cmp -s "$rule" "$ownership_copy"; then
            rm -f "$rule"
        elif [ -e "$rule" ]; then
            printf 'warning: %s was modified; the installer did not remove it\n' "$rule" >&2
        fi
        rm -f "$ownership_copy"
    fi
}

codex_home() {
    if [ -n "${CODEX_HOME:-}" ]; then
        printf '%s' "$CODEX_HOME"
    else
        printf '%s/.codex' "${HOME:?HOME is required for Codex user scope}"
    fi
}

codex_user_skills() {
    printf '%s/.agents/skills' "${HOME:?HOME is required for Codex user scope}"
}

codex_managed_paths() {
    printf '.agents/rules-for-ai\n'
    for skill_dir in "$ROOT"/skills/*/; do
        printf '.agents/skills/%s\n' "$(basename "$skill_dir")"
    done
}

codex_user_install() {
    home_dir=$(codex_home)
    support_dir="$home_dir/rules-for-ai"
    install_owned_rule "$home_dir/AGENTS.md" "$support_dir/AGENTS.md"
    cp "$ROOT/LOCALE.default.md" "$support_dir/LOCALE.default.md"
    install_owned_skills "$(codex_user_skills)" "$support_dir/skills"
    printf 'installed Codex rules and skills for this user -- restart Codex to load them\n'
}

codex_user_uninstall() {
    home_dir=$(codex_home)
    support_dir="$home_dir/rules-for-ai"
    remove_owned_rule "$home_dir/AGENTS.md" "$support_dir/AGENTS.md"
    skills_dir=$(codex_user_skills)
    remove_owned_skills "$skills_dir" "$support_dir/skills"
    rm -rf "$support_dir"
    rmdir "$skills_dir" "$(dirname -- "$skills_dir")" "$home_dir" 2> /dev/null || :
    printf 'removed Codex rules and skills for this user -- restart Codex to unload them\n'
}

codex_project_install() {
    support_dir="$TARGET/.agents/rules-for-ai"
    install_owned_rule "$TARGET/AGENTS.md" "$support_dir/AGENTS.md"
    mkdir -p "$support_dir"
    cp "$ROOT/LOCALE.default.md" "$support_dir/LOCALE.default.md"
    install_owned_skills "$TARGET/.agents/skills" "$support_dir/skills"
    if [ "$SCOPE" = local ]; then
        exclude=$(exclude_file)
        mkdir -p "$(dirname -- "$exclude")"
        [ -f "$exclude" ] || : > "$exclude"
        {
            [ -f "$support_dir/AGENTS.md" ] && printf '/AGENTS.md\n'
            codex_managed_paths
        } | while IFS= read -r path; do
            tracked_path=${path#/}
            if git -C "$TARGET" ls-files --error-unmatch "$tracked_path" > /dev/null 2>&1; then
                printf 'warning: %s is already tracked; local scope cannot hide it -- use project scope\n' "$path" >&2
            fi
            grep -qxF "$path" "$exclude" || printf '%s\n' "$path" >> "$exclude"
        done
    fi
    printf 'installed Codex rules and skills into %s (%s scope)\n' "$TARGET" "$SCOPE"
}

codex_project_uninstall() {
    support_dir="$TARGET/.agents/rules-for-ai"
    had_ownership_copy=0
    [ -f "$support_dir/AGENTS.md" ] && had_ownership_copy=1
    remove_owned_rule "$TARGET/AGENTS.md" "$support_dir/AGENTS.md"
    remove_owned_skills "$TARGET/.agents/skills" "$support_dir/skills"
    rm -rf "$support_dir"
    if [ "$SCOPE" = local ]; then
        exclude=$(exclude_file)
        if [ -f "$exclude" ]; then
            patterns=$(mktemp)
            kept=$(mktemp)
            {
                [ "$had_ownership_copy" -eq 1 ] && printf '/AGENTS.md\n'
                codex_managed_paths
            } > "$patterns"
            grep -vxF -f "$patterns" "$exclude" > "$kept" || :
            mv "$kept" "$exclude"
            rm -f "$patterns"
        fi
    fi
    rmdir "$TARGET/.agents/skills" "$TARGET/.agents" 2> /dev/null || :
    printf 'removed Codex rules and skills from %s (%s scope)\n' "$TARGET" "$SCOPE"
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

user_hooks_file() {
    printf '%s/.cursor/hooks.json' "$HOME"
}

# If the user has no hooks file, write this canonical ~/.cursor/hooks.json.
# User hooks run with ~/.cursor as the current directory.
# Thus, the commands use single-quoted absolute paths to support spaces in $HOME.
cursor_user_hooks_json() {
    dest=$(cursor_user_dest)
    cat <<EOF
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      { "command": "sh '$dest/hooks/session-start-cursor.sh'" }
    ],
    "beforeShellExecution": [
      { "command": "sh '$dest/hooks/pr-template-check-cursor.sh'" }
    ]
  }
}
EOF
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
    # The hooks.json policy is the same as the project-scope policy.
    # If the file is absent or unchanged, write the complete file.
    # Do not merge content into a file that another tool owns.
    hooks_file=$(user_hooks_file)
    if [ -f "$hooks_file" ] && ! hooks_json_owned cursor_user_hooks_json "$hooks_file"; then
        printf 'warning: %s already exists; add these entries manually:\n' "$hooks_file" >&2
        printf '  sessionStart:         { "command": "sh '\''%s/hooks/session-start-cursor.sh'\''" }\n' "$dest" >&2
        printf '  beforeShellExecution: { "command": "sh '\''%s/hooks/pr-template-check-cursor.sh'\''" }\n' "$dest" >&2
    else
        cursor_user_hooks_json > "$hooks_file"
    fi
    # Cursor can import Claude Code plugins from ~/.claude/plugins.
    # A second copy can load the plugin two times.
    if grep -qs "\"$PLUGIN@" "$HOME/.claude/settings.json"; then
        printf 'warning: %s is also enabled for Claude Code; Cursor may import it from ~/.claude/plugins as well\n' "$PLUGIN" >&2
    fi
    printf 'installed to %s -- restart Cursor to load it\n' "$dest"
}

cursor_user_uninstall() {
    dest=$(cursor_user_dest)
    hooks_file=$(user_hooks_file)
    if hooks_json_owned cursor_user_hooks_json "$hooks_file"; then
        rm -f "$hooks_file"
    elif grep -qsF "$dest/hooks/session-start-cursor.sh" "$hooks_file"; then
        printf 'warning: %s was modified; remove the rules-for-ai entries manually\n' "$hooks_file" >&2
    fi
    rm -rf "$dest"
    printf 'removed %s -- restart Cursor to unload it\n' "$dest"
}
exclude_file() {
    printf '%s/info/exclude' "$(git -C "$TARGET" rev-parse --absolute-git-dir)"
}

# If the target has no hooks file, write this canonical .cursor/hooks.json.
# The commands use relative paths because project hooks run from the project root.
# A cursor-agent test on 2026-07-10 supplied evidence for this behavior.
cursor_hooks_json() {
    cat <<'EOF'
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      { "command": "sh .cursor/rules-for-ai/session-start-cursor.sh" }
    ],
    "beforeShellExecution": [
      { "command": "sh .cursor/rules-for-ai/pr-template-check-cursor.sh" }
    ]
  }
}
EOF
}

# hooks_json_owned <canonical-fn> <path> compares a hooks file with canonical content.
# A matching file belongs to this installer, which can replace or remove it.
hooks_json_owned() {
    "$1" | cmp -s - "$2" 2> /dev/null
}

cursor_project_install() {
    mkdir -p "$TARGET/.cursor/rules" "$TARGET/.cursor/skills"
    cp "$ROOT/rules/agents.mdc" "$TARGET/.cursor/rules/agents.mdc"
    for skill_dir in "$ROOT"/skills/*/; do
        skill=$(basename "$skill_dir")
        rm -rf "${TARGET:?}/.cursor/skills/$skill"
        cp -R "${skill_dir%/}" "$TARGET/.cursor/skills/$skill"
    done
    mkdir -p "$TARGET/.cursor/rules-for-ai"
    for file in $CURSOR_SUPPORT_FILES; do
        cp "$ROOT/hooks/$file" "$TARGET/.cursor/rules-for-ai/$file"
    done
    # Copy the locale default so the session hook uses the same resolution order.
    cp "$ROOT/LOCALE.default.md" "$TARGET/.cursor/rules-for-ai/LOCALE.default.md"
    # If hooks.json is absent or unchanged, write the complete file.
    # Do not merge content into a file that another tool owns.
    if [ -f "$TARGET/.cursor/hooks.json" ] && ! hooks_json_owned cursor_hooks_json "$TARGET/.cursor/hooks.json"; then
        printf 'warning: %s/.cursor/hooks.json already exists; add these entries manually:\n' "$TARGET" >&2
        printf '  sessionStart:         { "command": "sh .cursor/rules-for-ai/session-start-cursor.sh" }\n' >&2
        printf '  beforeShellExecution: { "command": "sh .cursor/rules-for-ai/pr-template-check-cursor.sh" }\n' >&2
    else
        cursor_hooks_json > "$TARGET/.cursor/hooks.json"
    fi
    if [ "$SCOPE" = local ]; then
        exclude=$(exclude_file)
        mkdir -p "$(dirname -- "$exclude")"
        [ -f "$exclude" ] || : > "$exclude"
        {
            managed_paths
            # If this installation created hooks.json, exclude the file.
            # A team-owned file must remain in git status.
            hooks_json_owned cursor_hooks_json "$TARGET/.cursor/hooks.json" \
                && printf '.cursor/hooks.json\n'
        } | while IFS= read -r path; do
            if git -C "$TARGET" ls-files --error-unmatch "$path" > /dev/null 2>&1; then
                printf 'warning: %s is already tracked; local scope cannot hide it -- use project scope\n' "$path" >&2
            fi
            grep -qxF "$path" "$exclude" || printf '%s\n' "$path" >> "$exclude"
        done
    fi
    printf 'installed cursor files into %s (%s scope)\n' "$TARGET" "$SCOPE"
}

cursor_project_uninstall() {
    # Determine ownership before you remove files.
    if hooks_json_owned cursor_hooks_json "$TARGET/.cursor/hooks.json"; then
        owned_hooks=1
    else
        owned_hooks=0
    fi
    managed_paths | while IFS= read -r path; do
        rm -rf "${TARGET:?}/$path"
    done
    if [ "$owned_hooks" = 1 ]; then
        rm -f "$TARGET/.cursor/hooks.json"
    elif grep -qsF 'session-start-cursor.sh' "$TARGET/.cursor/hooks.json"; then
        printf 'warning: %s/.cursor/hooks.json was modified; remove the rules-for-ai sessionStart entry manually\n' "$TARGET" >&2
    fi
    if [ "$SCOPE" = local ]; then
        exclude=$(exclude_file)
        if [ -f "$exclude" ]; then
            patterns=$(mktemp)
            kept=$(mktemp)
            {
                managed_paths
                [ "$owned_hooks" = 1 ] && printf '.cursor/hooks.json\n'
            } > "$patterns"
            grep -vxF -f "$patterns" "$exclude" > "$kept" || :
            mv "$kept" "$exclude"
            rm -f "$patterns"
        fi
    fi
    rmdir "$TARGET/.cursor/skills" "$TARGET/.cursor/rules-for-ai" "$TARGET/.cursor/rules" "$TARGET/.cursor" 2> /dev/null || :
    printf 'removed cursor files from %s (%s scope)\n' "$TARGET" "$SCOPE"
}

# --- dispatch --------------------------------------------------------------

case "$PLATFORM" in
    claude)
        [ "$SCOPE" = user ] || resolve_target
        if [ "$ACTION" = install ]; then claude_install; else claude_uninstall; fi
        ;;
    codex)
        if [ "$SCOPE" = user ]; then
            if [ "$ACTION" = install ]; then codex_user_install; else codex_user_uninstall; fi
        else
            resolve_target
            if [ "$ACTION" = install ]; then codex_project_install; else codex_project_uninstall; fi
        fi
        ;;
    cursor)
        if [ "$SCOPE" = user ]; then
            if [ "$ACTION" = install ]; then cursor_user_install; else cursor_user_uninstall; fi
        else
            resolve_target
            if [ "$ACTION" = install ]; then cursor_project_install; else cursor_project_uninstall; fi
        fi
        ;;
esac
