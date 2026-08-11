# Cursor

This document explains the Cursor installation and the locale process.

Install with [rules-for-ai.sh](../rules-for-ai.sh):

```bash
./rules-for-ai.sh install cursor <user|project|local> [path/to/repo]
```

Run only this command. The remaining sections describe the internal actions of `rules-for-ai.sh`.

Use these sections to audit or reproduce the installation.

## Scopes and artifacts

### user

The installer clones the repository into `~/.cursor/plugins/local/rules-for-ai/`. Cursor uses this directory for local plugins.

Restart Cursor after an installation or update.

The clone contains the rules, all skills, and the bundled `LOCALE.default.md`. The rules use `rules/agents.mdc` and `alwaysApply`.

The installer adds hooks through `~/.cursor/hooks.json`. User hooks run with `~/.cursor` as the current directory.

Thus, the hook commands contain absolute paths to the clone. If the hooks file is absent or unchanged, the installer writes it.

If another tool owns `hooks.json`, the installer does not change it. The installer prints these entries for manual addition:

```json
{ "command": "sh '~/.cursor/plugins/local/rules-for-ai/hooks/session-start-cursor.sh'" }
{ "command": "sh '~/.cursor/plugins/local/rules-for-ai/hooks/pr-template-check-cursor.sh'" }
```

The first entry is for `sessionStart`. The second entry is for `beforeShellExecution`.

The installer prints both entries with an expanded `$HOME` value.

Teams and Enterprise users can import the repository from Settings → Plugins → Import from Repo. This method loads rules and skills.

This method does not register hooks. Cursor finds plugin hooks in `hooks/hooks.json`.

This repository must keep that path in the Claude Code hook format because `claude plugin validate` reads it.

Thus, Cursor hooks use the `hooks.json` files that the installer writes.

> [!WARNING]
> If Claude Code already enables the plugin, do not install it at the Cursor **user** scope. Cursor can import `~/.claude/plugins/`.
>
> A second installation can load the plugin two times.

Uninstall removes `~/.cursor/plugins/local/rules-for-ai/`. It also removes the `~/.cursor/hooks.json` file that the installer created.

Uninstall does not remove a modified or foreign file. If such a file contains plugin entries, uninstall prints a warning.

Restart Cursor to unload the plugin.

### project

The installer copies these files into the target repository. Commit the files so that teammates do not need an installation.

Cursor can ask each developer to approve the hooks.

| Path | Source |
|------|--------|
| `.cursor/rules/agents.mdc` | `rules/agents.mdc` |
| `.cursor/skills/*` | `skills/*` (every skill, `hashiiiii-locale` included) |
| `.cursor/rules-for-ai/resolve-locale.sh` | `hooks/resolve-locale.sh` |
| `.cursor/rules-for-ai/resolve-scoped-locale.sh` | `hooks/resolve-scoped-locale.sh` |
| `.cursor/rules-for-ai/session-start-cursor.sh` | `hooks/session-start-cursor.sh` |
| `.cursor/rules-for-ai/json-escape.sh` | `hooks/json-escape.sh` |
| `.cursor/rules-for-ai/check-pr-template.sh` | `hooks/check-pr-template.sh` |
| `.cursor/rules-for-ai/pr-template-check-cursor.sh` | `hooks/pr-template-check-cursor.sh` |
| `.cursor/rules-for-ai/LOCALE.default.md` | `LOCALE.default.md` |
| `.cursor/hooks.json` | If the file is absent or unchanged, the installer writes it. |

`hashiiiii-locale` can write a user, project, or local locale file. The locale scope is independent of the plugin installation scope.

If `.cursor/hooks.json` differs from the installer file, install does not replace it. Install prints these entries for manual addition:

```json
{ "command": "sh .cursor/rules-for-ai/session-start-cursor.sh" }
{ "command": "sh .cursor/rules-for-ai/pr-template-check-cursor.sh" }
```

If the installer owns `hooks.json`, the file has this content:

```json
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
```

### local

The **local** scope uses the same files as the **project** scope. It also adds entries to `.git/info/exclude`.

Thus, these files do not occur in `git status`. If this installation created `.cursor/hooks.json`, the scope also excludes it.

A team-owned `hooks.json` remains in `git status`.

If Git already tracks a path, the local scope cannot hide it. Use the project scope instead.

## How locale reaches context

Every scope uses the same `session-start-cursor.sh` hook. After approval, Cursor adds the `additional_context` output to the model context.

The hook adds only the resolved locale keys. The always-on rules use `agents.mdc` with `alwaysApply`.

The hook reads the first entry in `workspace_roots`. This entry is the primary root for locale resolution in a multi-root workspace.

For older input without `workspace_roots`, a copied project hook gets the root from its `.cursor/rules-for-ai/` location.

The scope resolver finds the Git repository. The first existing file wins as a whole:

1. `<absolute-git-dir>/rules-for-ai/LOCALE.md`
2. `<repo>/.rules-for-ai/LOCALE.md`
3. `$XDG_CONFIG_HOME/rules-for-ai/LOCALE.md` (default `~/.config/rules-for-ai/LOCALE.md`)
4. `LOCALE.default.md` next to the hook or at the plugin root
5. Inline `en_US` for all five keys

The locale layers do not merge. A root-level `LOCALE.md` is not part of this order.

If project instructions specify a language, they take precedence over the resolved keys.

Use `hashiiiii-locale` to create or update a locale scope.

## Pull request template check

`beforeShellExecution` runs `pr-template-check-cursor.sh`. This script is the Cursor envelope for `check-pr-template.sh`.

The Claude Code PreToolUse hook uses the same check. If a template heading is absent, the check rejects the inline body.

The `agent_message` value contains the reason. The check permits all other bodies.

This permission includes bodies that use `--body-file` or `--fill`, because the check cannot read them.

The check uses the payload `cwd` to find the pull request template. Thus, the check also works from user hooks in `~/.cursor`.
