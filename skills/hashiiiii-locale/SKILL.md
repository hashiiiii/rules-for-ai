---
name: hashiiiii-locale
description: Use when setting or changing rules-for-ai locale preferences. Writes the user-level LOCALE.md.
---

# Locale Setup

Manage the user-level LOCALE file that rules-for-ai resolves at session start.

## Resolution order (first existing file wins)

1. `~/.config/rules-for-ai/LOCALE.md` (user level; respect `$XDG_CONFIG_HOME` when set)
2. Bundled `LOCALE.default.md` (all `en_US`)

The winning file is used as a whole; layers never merge. That is why every LOCALE file must carry all four keys.

There is no project-level LOCALE file. A project-specific language policy is an ordinary project instruction: it belongs in that project's `CLAUDE.md` / `AGENTS.md` (e.g. "Write issues in English"), and project instructions override resolved locale keys.

## When to Use

- When the user asks to set or change the language of issues, code comments, or logs
- When the user wants a project-specific policy — do not write a LOCALE file; add the policy to that project's `CLAUDE.md` / `AGENTS.md` instead

## Arguments

- A single POSIX-style tag (`ja_JP`): apply it to all four keys
- Key=value pairs, one per artifact:

| Key | Artifact |
|-----|----------|
| `issues` | Issues |
| `comments` | Code comments |
| `logs` | Log messages |
| `test-logs` | Test log messages |

Example: `issues=ja_JP comments=ja_JP logs=en_US test-logs=en_US`

- No arguments: ask the user about each of the four artifacts individually — locales may differ per artifact.

## Writing the file

Always target `~/.config/rules-for-ai/LOCALE.md` (`$XDG_CONFIG_HOME/rules-for-ai/LOCALE.md` when `XDG_CONFIG_HOME` is set). Never write a LOCALE file into a project.

1. Validate keys: only the four keys above exist; reject anything else
2. Use POSIX-style tags (`ja_JP`, `en_US`, `en_GB`) as given; do not translate or normalize
3. Write strict `key=value` lines: no spaces around `=`, one key per line, LF line endings
4. Create the target directory when missing
5. Write atomically: write a temp file in the same directory, then `mv` it over the target
6. Always write all four keys; fill unspecified keys from the currently resolved values

File format (exactly this shape):

    # Locale

    issues=ja_JP
    comments=ja_JP
    logs=en_US
    test-logs=en_US

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Writing a project-root `LOCALE.md` | The project layer does not exist; put project policy in that project's `CLAUDE.md` / `AGENTS.md` |
| Leaving keys out | Always write all four keys |
| Inventing keys like `commits` | Only the four keys in the table exist |
| Spaces around `=` (`issues = ja_JP`) | Strict `issues=ja_JP` only |
