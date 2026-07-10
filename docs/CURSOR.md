# Cursor

How rules-for-ai installs under Cursor, and how locale keys reach the model.

Install with [rules-for-ai.sh](../rules-for-ai.sh):

```bash
./rules-for-ai.sh install cursor <user|project|local> [target-dir]
```

## Scopes and artifacts

### user

Clones the repo into `~/.cursor/plugins/local/rules-for-ai/`. Restart Cursor after install or update.

The full plugin tree is present, including `hashiiiii-locale`, `LOCALE.default.md`, skills, and rules.

Teams/Enterprise can import the repo from Settings → Plugins → Import from Repo instead of using the installer.

> [!WARNING]
> Already enabled for Claude Code? Cursor can import it from `~/.claude/plugins/` — do not also install at **cursor** **user** scope, or the plugin may load twice.

Uninstall removes `~/.cursor/plugins/local/rules-for-ai/` (restart Cursor to unload).

### project

Copies files into the target repo (commit them; teammates need no install, though Cursor may ask each developer to approve the hook):

| Path | Source |
|------|--------|
| `.cursor/rules/agents.mdc` | `rules/agents.mdc` |
| `.cursor/skills/hashiiiii-git/` | `skills/hashiiiii-git/` |
| `.cursor/skills/hashiiiii-issues/` | `skills/hashiiiii-issues/` |
| `.cursor/skills/hashiiiii-pull-request/` | `skills/hashiiiii-pull-request/` |
| `.cursor/rules-for-ai/resolve-locale.sh` | `hooks/resolve-locale.sh` |
| `.cursor/rules-for-ai/session-start-cursor.sh` | `hooks/session-start-cursor.sh` |
| `.cursor/hooks.json` | Written when absent or already identical to the installer's canonical file |

`hashiiiii-locale` is **not** copied. That skill writes user-level config only; put project language policy in the project's `CLAUDE.md` / `AGENTS.md` (or Cursor rules).

If `.cursor/hooks.json` already exists and is not byte-identical to the installer's file, install does not overwrite it. It prints the `sessionStart` entry to add manually:

```json
{ "command": "sh .cursor/rules-for-ai/session-start-cursor.sh" }
```

Canonical `hooks.json` when the installer owns the file:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      { "command": "sh .cursor/rules-for-ai/session-start-cursor.sh" }
    ]
  }
}
```

### local

Same files as **project**, plus entries in `.git/info/exclude` so they stay out of `git status`. `.cursor/hooks.json` is excluded only when this install created it (byte-identical to the canonical file); a team-owned `hooks.json` keeps showing up in git status.

If a path is already tracked, local scope cannot hide it — use project scope instead.

## How locale reaches context

| Scope | Delivery |
|-------|----------|
| **user** | The model reads the cloned plugin (rules, skills, bundled `LOCALE.default.md`). This installer does not register a sessionStart hook at user scope. |
| **project / local** | After the developer approves the hook, `sessionStart` runs `sh .cursor/rules-for-ai/session-start-cursor.sh`, which emits a single-line JSON object `{"additional_context":"..."}`. Cursor injects that text. The hook adds only the resolved locale keys (`## Locale (resolved)`); always-on rules already ride on `.cursor/rules/agents.mdc` (`alwaysApply`). |

For project/local, `resolve-locale.sh` is called with only the user config path. The first existing file wins as a whole:

1. `$XDG_CONFIG_HOME/rules-for-ai/LOCALE.md` (default `~/.config/rules-for-ai/LOCALE.md`)
2. Inline `en_US` for all five keys

Project installs carry no bundled `LOCALE.default.md`, so without a user-level file the inline default wins.

A project-root `LOCALE.md` is not part of this chain. Project language policy belongs in that project's instructions, which override resolved keys when they state a language.

Create or update the user-level file with the `hashiiiii-locale` skill (available after a **user** install, or from Claude Code) — see [Getting Started → Locale](../README.md#locale) in the README.
