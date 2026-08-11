---
name: hashiiiii-locale
description: Use this skill to set or change locale preferences for a user, project, or local Git worktree.
---

# Locale Setup

Set locale preferences at the scope that the user selects. Do not use the plugin installation scope to select the locale scope.

## Scope Selection

Accept `user`, `project`, or `local` as a bare argument. Also accept `scope=<scope>`.

If the request has no scope, ask for the scope first. Then ask for the locale values.

Do not infer the scope from the current directory or plugin installation.

Before each write, state the selected scope, exact target path, and sharing behavior.

| Scope | Target | Sharing behavior |
| --- | --- | --- |
| `user` | `${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md` | Use the locale in all projects for this user. |
| `project` | `<repo>/.rules-for-ai/LOCALE.md` | Commit the locale for team use. |
| `local` | `<absolute-git-dir>/rules-for-ai/LOCALE.md` | Use the locale in this Git worktree, outside `git status`. |

For `project` or `local`, use `git rev-parse --show-toplevel` to find the repository.

If the command fails, stop without a write.

For `local`, get `<absolute-git-dir>` from `git rev-parse --absolute-git-dir`. This path keeps linked worktree preferences separate.

Do not commit a project file automatically. Do not add a local file to `.gitignore` or `.git/info/exclude`.

## Resolution Order

The first existing file wins as a whole:

1. `<absolute-git-dir>/rules-for-ai/LOCALE.md`
2. `<repo>/.rules-for-ai/LOCALE.md`
3. `${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md`
4. Bundled `LOCALE.default.md`
5. Inline `en_US` values

Project instructions in `CLAUDE.md` or `AGENTS.md` take precedence over the resolved locale keys.

## Locale Arguments

- A single POSIX-style tag, such as `ja_JP`, sets all five keys.
- Key-value arguments set separate keys.
- If the request has no locale values, ask about each artifact after scope selection.

| Key | Artifact |
| --- | --- |
| `issues` | Issues |
| `pull-requests` | Pull requests |
| `comments` | Code comments |
| `logs` | Log messages |
| `test-logs` | Test log messages |

Example: `local issues=ja_JP pull-requests=ja_JP comments=ja_JP logs=en_US test-logs=en_US`

Reject unknown scopes and keys. Use each POSIX-style tag as given.

Do not translate a tag. Do not normalize a tag.

## Partial Updates

Always write all five keys. For omitted keys, use the existing target file first.

If the target does not supply a key, use only lower-priority scopes:

| Target | Fallback order |
| --- | --- |
| `local` | Project, user, bundled default, inline `en_US` |
| `project` | User, bundled default, inline `en_US` |
| `user` | Bundled default, inline `en_US` |

Do not use a higher-priority scope as a fallback. Do not put a local value in a project or user file.

## File Write

Write strict `key=value` lines. Do not put spaces around `=`.

Use LF line endings and this exact format:

    # Locale

    issues=ja_JP
    pull-requests=ja_JP
    comments=ja_JP
    logs=en_US
    test-logs=en_US

If the target directory does not exist, create it. Write a temporary file in that directory.

Then move the temporary file over the target with an atomic operation.

## Common Mistakes

| Mistake | Required action |
| --- | --- |
| Use the plugin installation scope | Ask for the locale scope. |
| Write a repository request to the user file | Use the selected repository target. |
| Write a local file in the worktree | Use the absolute Git directory. |
| Copy local values into a project file | Use only project fallback scopes. |
| Omit keys | Fill all five keys. Then write them. |
