# Claude Code

How rules-for-ai installs under Claude Code, and how locale keys reach the model.

Install with [rules-for-ai.sh](../rules-for-ai.sh):

```bash
./rules-for-ai.sh install claude <user|project|local> [target-dir]
```

Requires the Claude Code CLI. Scopes map to `claude plugin ... --scope`.

## Scopes and settings

| Scope | Settings file | Notes |
|-------|---------------|-------|
| **user** | `~/.claude/settings.json` | Every project on this machine |
| **project** | `<repo>/.claude/settings.json` | Commit it; teammates accept the trust prompt |
| **local** | `<repo>/.claude/settings.local.json` | Not tracked; no `.gitignore` change needed |

Install runs, from the appropriate directory (`~` for user, the target repo for project/local):

1. `claude plugin marketplace add <source> --scope <scope>`
2. `claude plugin marketplace update hashiiiii`
3. `claude plugin install rules-for-ai@hashiiiii --scope <scope>`

**project** also pins the marketplace and enables the plugin in `.claude/settings.json`. The same block can be added by hand:

```json
{
  "extraKnownMarketplaces": {
    "hashiiiii": {
      "source": { "source": "github", "repo": "hashiiiii/rules-for-ai" }
    }
  },
  "enabledPlugins": { "rules-for-ai@hashiiiii": true }
}
```

Installed at **user** scope but want it off in one repo? Add to that repo's `.claude/settings.json`:

```json
{ "enabledPlugins": { "rules-for-ai@hashiiiii": false } }
```

Prefer the UI? Run `/plugin marketplace add hashiiiii/rules-for-ai`, then `/plugin install rules-for-ai@hashiiiii`.

Uninstall:

```bash
./rules-for-ai.sh uninstall claude <user|project|local> [target-dir]
```

That runs `claude plugin uninstall rules-for-ai@hashiiiii --scope <scope>`. Remove the marketplace separately with `claude plugin marketplace remove hashiiiii` if nothing else uses it.

## What lands where

Claude Code loads the plugin from its plugin cache / marketplace install. The repo's own files are not copied into the target project (unlike Cursor project/local). The live plugin tree includes:

| Path in the plugin | Role |
|--------------------|------|
| `AGENTS.md` | Always-on behavioral principles |
| `LOCALE.default.md` | Bundled locale fallback |
| `hooks/hooks.json` | SessionStart and PreToolUse wiring |
| `hooks/session-start-claude-code.sh` | SessionStart command |
| `hooks/resolve-locale.sh` | Shared locale resolver |
| `hooks/check-pr-template.sh` | Shared PR template check |
| `hooks/pr-template-check-claude-code.sh` | PreToolUse envelope over the shared check |
| `skills/*` | Including `hashiiiii-locale` |

The `*-cursor.sh` hooks and `json-escape.sh` also ride along; Claude Code never runs them.

## How locale reaches context

Each session, the SessionStart hook (`hooks/session-start-claude-code.sh`) prints:

1. The full contents of `AGENTS.md`
2. A `## Locale (resolved)` block with the five keys

Resolution is delegated to `hooks/resolve-locale.sh`. The first existing file wins as a whole; layers never merge:

1. `$XDG_CONFIG_HOME/rules-for-ai/LOCALE.md` (default `~/.config/rules-for-ai/LOCALE.md`)
2. `$CLAUDE_PLUGIN_ROOT/LOCALE.default.md`
3. Inline `en_US` for all five keys (so the resolved block is never empty)

A project-root `LOCALE.md` is ignored. Project language policy belongs in that project's `CLAUDE.md` / `AGENTS.md`, which override resolved keys when they state a language.

Create or update the user-level file with the `hashiiiii-locale` skill — see [Getting Started → Locale](../README.md#locale) in the README.
