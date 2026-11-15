---
name: hashiiiii-locale
description: Use this skill to set or change locale preferences for a user, project, or local Git worktree.
---

# Locale Preferences

Write all five locale keys to the scope the user selects. Do not infer the scope from the current directory or plugin installation.

## Scope

Accept `user`, `project`, or `local`, either as a bare argument or as `scope=<scope>`. If the user does not select a scope, ask before proceeding. Before writing, state the selected scope, exact target path, and sharing behavior.

| Scope | File | Sharing |
| --- | --- | --- |
| `user` | `${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md` | All projects for this user |
| `project` | `<repo>/.rules-for-ai/LOCALE.md` | Anyone using the repository |
| `local` | `<absolute-git-dir>/rules-for-ai/LOCALE.md` | This Git worktree only |

For `project` and `local`, get the repository with `git rev-parse --show-toplevel`. For `local`, get the directory with `git rev-parse --absolute-git-dir`. Stop if either command fails. Do not commit project files automatically or add local files to Git ignore rules.

## Locale Values

A single POSIX-style locale tag, such as `ja_JP`, sets all five keys. Key-value arguments set individual keys. If no locale values are given, ask which locale to use for each artifact. Reject unknown scopes and keys. Keep each tag as supplied; do not translate or normalize it.

| Key | Applies to |
| --- | --- |
| `issues` | Issues |
| `pull-requests` | Pull requests |
| `comments` | Code comments |
| `logs` | Log messages |
| `test-logs` | Test log messages |

For a partial update, keep existing target values first. Fill missing keys only from lower-priority scopes:

| Target | Fallback order |
| --- | --- |
| `local` | Project, user, bundled default, `en_US` |
| `project` | User, bundled default, `en_US` |
| `user` | Bundled default, `en_US` |

Always write all five keys. Never copy local values into project or user settings. Locale resolution uses the first existing file as a whole; project instructions take precedence over locale keys.

## Write the File

Use LF line endings and strict `key=value` lines with no spaces around `=`:

```text
# Locale

issues=ja_JP
pull-requests=ja_JP
comments=ja_JP
logs=en_US
test-logs=en_US
```

Create the target directory if needed. Write a temporary file in that directory, then atomically move it over the target.
