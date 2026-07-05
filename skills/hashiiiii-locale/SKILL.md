---
name: hashiiiii-locale
description: Use when setting or changing rules-for-ai locale preferences, or when onboarding says no user-level locale is set. Writes the user-level or project-level LOCALE.md.
---

# Locale Setup

Manage the LOCALE tables that rules-for-ai resolves at session start.

## Resolution order (per row, first hit wins)

1. `LOCALE.md` at the project root
2. `~/.config/rules-for-ai/LOCALE.md` (user level; respect `$XDG_CONFIG_HOME` when set)
3. Bundled `LOCALE.default.md` (all `en_US`)

## When to Use

- When the session context says no user-level locale preference is set (onboarding)
- When the user asks to change the language of issues, code comments, or logs
- When the user wants a project-specific override

## Arguments

- A single BCP 47 tag (`ja_JP`): apply it to all four artifacts
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

Target `~/.config/rules-for-ai/LOCALE.md` by default (`$XDG_CONFIG_HOME/rules-for-ai/LOCALE.md` when `XDG_CONFIG_HOME` is set). Write a project-root `LOCALE.md` instead only when the user asks for a project-specific override.

1. Validate keys: only the four keys above exist; reject anything else
2. Use BCP 47 tags (`ja_JP`, `en_US`, `en_GB`) as given; do not translate or normalize
3. Create the target directory when missing
4. Write atomically: write a temp file in the same directory, then `mv` it over the target
5. Always write all four rows; fill unspecified rows from the currently resolved values

File format (exactly this shape):

    # Locale

    | Artifact | Language |
    |----------|----------|
    | Issues | ja_JP |
    | Code comments | ja_JP |
    | Log messages | en_US |
    | Test log messages | en_US |

## When the user accepts the defaults

Write the default table (all `en_US`) to the user-level path unchanged. The existence of the file records the decision, so onboarding never fires again.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Writing the project file during onboarding | Onboarding targets the user-level path |
| Leaving rows out | Always write all four rows |
| Inventing keys like `commits` | Only the four keys in the table exist |
