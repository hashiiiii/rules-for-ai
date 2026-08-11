# AGENTS

- Premature Optimization is the Root of All Evil
- If it hurts, do it more often
- Don't live with broken windows
- Never compromise
- Never assume the unsaid intentions
- Insert a half-width space between full-width and half-width characters
- Don't use emojis
- Prioritize comments in tests
- Write comments for WHY, not WHAT
- Never use mocks or stubs

## Language

- Project instructions (`CLAUDE.md` / `AGENTS.md`) override resolved locale keys
- If resolved locale keys are already in context (hook-injected), follow them
- Otherwise read the first existing locale file in this order:
  1. `<absolute-git-dir>/rules-for-ai/LOCALE.md`
  2. `<repo>/.rules-for-ai/LOCALE.md`
  3. `~/.config/rules-for-ai/LOCALE.md`
  4. Bundled `LOCALE.default.md`
- Get `<absolute-git-dir>` with `git rev-parse --absolute-git-dir`
- If no locale file exists, use `en_US` for all keys

## Git

- Follow the `hashiiiii-git` skill for git operations

## Issues

- Follow the `hashiiiii-issues` skill for GitHub issue operations

## Pull Requests

- Follow the `hashiiiii-pull-request` skill for GitHub pull request operations

## Images

- Follow the `hashiiiii-images` skill when creating image assets (logos, icons, favicons, header images)
