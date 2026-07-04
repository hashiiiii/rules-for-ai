#!/bin/sh
# Claude Code statusLine command
# Mirrors the zsh PROMPT from ~/.zshrc:
#   %F{blue}%~%f${vcs_info_msg_0_} %(?.%F{green}.%F{red})❯%f
# Trailing ❯ is omitted as it is not appropriate for a status line.

input=$(cat)

current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
home_dir="$HOME"

# Replicate %~ (replace $HOME prefix with ~)
case "$current_dir" in
  "$home_dir"*)
    display_dir="~${current_dir#"$home_dir"}"
    ;;
  *)
    display_dir="$current_dir"
    ;;
esac

# Git branch and dirty state (mirrors vcs_info: branch in magenta, unstaged=* staged=+ in yellow)
git_branch=""
git_markers=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -n "$git_branch" ]; then
    unstaged=$(git -C "$current_dir" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    staged=$(git -C "$current_dir" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    if [ "$unstaged" -gt 0 ]; then git_markers="${git_markers}*"; fi
    if [ "$staged" -gt 0 ]; then git_markers="${git_markers}+"; fi
  fi
fi

# Context window usage
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Build the status line
# Blue current dir
printf '\033[34m%s\033[0m' "$display_dir"

# Magenta branch + yellow dirty markers
if [ -n "$git_branch" ]; then
  printf ' \033[35m%s\033[0m' "$git_branch"
  if [ -n "$git_markers" ]; then
    printf '\033[33m%s\033[0m' "$git_markers"
  fi
fi

# Context remaining (dim white)
if [ -n "$remaining" ]; then
  printf ' \033[2mctx:%.0f%%\033[0m' "$remaining"
fi

echo ""
