# AGENTS

- Do not optimize too early
- If a task causes difficulty, do it more frequently
- Correct small defects before they become larger defects
- Never compromise
- Never assume intentions that the user did not state
- Insert a half-width space between full-width and half-width characters
- Do not use emoji
- Prioritize comments in tests
- Write comments that explain the reason
- Do not write comments that only explain the action
- Never use mocks or stubs

## Language

- Project instructions (`CLAUDE.md` / `AGENTS.md`) take precedence over resolved locale keys
- If the context contains resolved locale keys, use them
- If the context does not contain resolved locale keys, read the first existing locale file in this order:
  1. `<absolute-git-dir>/rules-for-ai/LOCALE.md`
  2. `<repo>/.rules-for-ai/LOCALE.md`
  3. `~/.config/rules-for-ai/LOCALE.md`
  4. Bundled `LOCALE.default.md` in one of these locations:
     - `$CODEX_HOME/rules-for-ai/` for Codex user installations
     - `<repo>/.agents/rules-for-ai/` for Codex project and local installations
     - `<repo>/.cursor/rules-for-ai/` for Cursor project and local installations
     - The plugin root for other installations
- Get `<absolute-git-dir>` with `git rev-parse --absolute-git-dir`
- If no locale file exists, use `en_US` for all keys

## Git

- Use the `hashiiiii-git` skill for Git operations

## Issues

- Use the `hashiiiii-issues` skill for GitHub issue operations

## Pull Requests

- Use the `hashiiiii-pull-request` skill for GitHub pull request operations

## Images

- Use the `hashiiiii-images` skill to create image assets (logos, icons, favicons, and header images)
