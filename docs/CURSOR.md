# Cursor

How rules-for-ai installs under Cursor, and how locale keys reach the model.

Install with [rules-for-ai.sh](../rules-for-ai.sh):

```bash
./rules-for-ai.sh install cursor <user|project|local> [target-dir]
```

## Scopes and artifacts

### user

Clones the repo into `~/.cursor/plugins/local/rules-for-ai/`. Restart Cursor after install or update.

The full plugin tree is present: rules (`rules/agents.mdc`, `alwaysApply`), every skill including `hashiiiii-locale`, and the bundled `LOCALE.default.md`.

Hooks ride on `~/.cursor/hooks.json` (user-level hooks run with cwd `~/.cursor`, so the commands carry absolute paths into the clone). The file is written wholesale only when it is absent or already ours — an existing `hooks.json` belonging to another tool is never modified; install warns and prints the two entries to add manually:

```json
{ "command": "sh '~/.cursor/plugins/local/rules-for-ai/hooks/session-start-cursor.sh'" }
{ "command": "sh '~/.cursor/plugins/local/rules-for-ai/hooks/pr-template-check-cursor.sh'" }
```

(`sessionStart` and `beforeShellExecution` respectively; the installer prints them with `$HOME` expanded.)

Teams/Enterprise can import the repo from Settings → Plugins → Import from Repo instead of using the installer; that path loads rules and skills but registers no hooks.

> [!WARNING]
> Already enabled for Claude Code? Cursor can import it from `~/.claude/plugins/` — do not also install at **cursor** **user** scope, or the plugin may load twice.

Uninstall removes `~/.cursor/plugins/local/rules-for-ai/` and the `~/.cursor/hooks.json` it created (a modified or foreign file is left alone, with a warning when our entries are embedded in it). Restart Cursor to unload.

### project

Copies files into the target repo (commit them; teammates need no install, though Cursor may ask each developer to approve the hooks):

| Path | Source |
|------|--------|
| `.cursor/rules/agents.mdc` | `rules/agents.mdc` |
| `.cursor/skills/hashiiiii-git/` | `skills/hashiiiii-git/` |
| `.cursor/skills/hashiiiii-issues/` | `skills/hashiiiii-issues/` |
| `.cursor/skills/hashiiiii-locale/` | `skills/hashiiiii-locale/` |
| `.cursor/skills/hashiiiii-pull-request/` | `skills/hashiiiii-pull-request/` |
| `.cursor/rules-for-ai/resolve-locale.sh` | `hooks/resolve-locale.sh` |
| `.cursor/rules-for-ai/session-start-cursor.sh` | `hooks/session-start-cursor.sh` |
| `.cursor/rules-for-ai/json-escape.sh` | `hooks/json-escape.sh` |
| `.cursor/rules-for-ai/check-pr-template.sh` | `hooks/check-pr-template.sh` |
| `.cursor/rules-for-ai/pr-template-check-cursor.sh` | `hooks/pr-template-check-cursor.sh` |
| `.cursor/rules-for-ai/LOCALE.default.md` | `LOCALE.default.md` |
| `.cursor/hooks.json` | Written when absent or already identical to the installer's canonical file |

`hashiiiii-locale` writes the user-level `~/.config/rules-for-ai/LOCALE.md` only — never a file inside the project — so shipping it here keeps project/local installs closed to the project. Project language policy still belongs in the project's `CLAUDE.md` / `AGENTS.md`.

If `.cursor/hooks.json` already exists and is not byte-identical to the installer's file, install does not overwrite it. It prints the entries to add manually:

```json
{ "command": "sh .cursor/rules-for-ai/session-start-cursor.sh" }
{ "command": "sh .cursor/rules-for-ai/pr-template-check-cursor.sh" }
```

Canonical `hooks.json` when the installer owns the file:

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

Same files as **project**, plus entries in `.git/info/exclude` so they stay out of `git status`. `.cursor/hooks.json` is excluded only when this install created it (byte-identical to the canonical file); a team-owned `hooks.json` keeps showing up in git status.

If a path is already tracked, local scope cannot hide it — use project scope instead.

## How locale reaches context

Every scope resolves through the same hook (`session-start-cursor.sh` emits `{"additional_context":"..."}`; Cursor injects that text after the developer approves the hook). The hook adds only the resolved locale keys (`## Locale (resolved)`); always-on rules already ride on `agents.mdc` (`alwaysApply`).

`resolve-locale.sh` picks the first existing file, whole-file, layers never merging:

1. `$XDG_CONFIG_HOME/rules-for-ai/LOCALE.md` (default `~/.config/rules-for-ai/LOCALE.md`)
2. `LOCALE.default.md` — next to the hook (`.cursor/rules-for-ai/` copy) or at the clone root (user scope)
3. Inline `en_US` for all five keys (so the resolved block is never empty)

A project-root `LOCALE.md` is not part of this chain. Project language policy belongs in that project's instructions, which override resolved keys when they state a language.

Create or update the user-level file with the `hashiiiii-locale` skill — see [Getting Started → Locale](../README.md#locale) in the README.

## Pull request template check

`beforeShellExecution` runs `pr-template-check-cursor.sh`, the Cursor envelope over the same `check-pr-template.sh` that backs the Claude Code PreToolUse hook. An inline `gh pr create` / `gh pr edit` body missing a template heading is denied with the reason in `agent_message`; everything else — including bodies the check cannot read (`--body-file`, `--fill`) — is allowed. The check locates the repository pull request template through the payload's `cwd`, so it also works from user-level hooks (which run in `~/.cursor`).
