# Claude Code

This document explains the Claude Code installation and the locale process.

Install with [rules-for-ai.sh](../rules-for-ai.sh):

```bash
./rules-for-ai.sh install claude <user|project|local> [path/to/repo]
```

The installation requires the Claude Code CLI. Each scope maps to `claude plugin ... --scope`.

Run only this command. The remaining sections describe the internal actions of `rules-for-ai.sh`.

Use these sections to audit or reproduce the installation.

## Scopes and settings

| Scope | Settings file | Notes |
|-------|---------------|-------|
| **user** | `~/.claude/settings.json` | Every project on this machine |
| **project** | `<repo>/.claude/settings.json` | Commit the file. Teammates accept the trust prompt. |
| **local** | `<repo>/.claude/settings.local.json` | Claude Code tells Git to ignore this file. The installation does not edit the repository `.gitignore`. |

For **project** and **local** scopes, install runs these commands in the target repository. The **user** scope works from any directory.

1. `claude plugin marketplace add <source> --scope <scope>`
2. `claude plugin marketplace update hashiiiii`
3. `claude plugin install rules-for-ai@hashiiiii --scope <scope>`

The **project** scope also pins the marketplace. It enables the plugin in `.claude/settings.json`.

To add the same block manually, use this content:

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

To disable a **user** installation in one repository, add this content to the repository `.claude/settings.json`:

```json
{ "enabledPlugins": { "rules-for-ai@hashiiiii": false } }
```

Commit `.claude/settings.json` to share the override.

To keep the override personal, put the same block in `.claude/settings.local.json`.

To install from Claude Code, run `/plugin marketplace add hashiiiii/rules-for-ai`. Then run `/plugin install rules-for-ai@hashiiiii`.

To uninstall, run:

```bash
./rules-for-ai.sh uninstall claude <user|project|local> [path/to/repo]
```

This command runs `claude plugin uninstall rules-for-ai@hashiiiii --scope <scope>`.

If no other plugin uses the marketplace, run `claude plugin marketplace remove hashiiiii`.

## What lands where

Claude Code loads the plugin from its plugin cache. It does not copy the repository files into the target project.

The installed plugin contains these files:

| Path in the plugin | Role |
|--------------------|------|
| `AGENTS.md` | Always-on behavioral principles |
| `LOCALE.default.md` | Bundled locale fallback |
| `hooks/hooks.json` | SessionStart and PreToolUse wiring |
| `hooks/session-start-claude-code.sh` | SessionStart command |
| `hooks/resolve-locale.sh` | Shared locale resolver |
| `hooks/resolve-scoped-locale.sh` | Scope candidate resolver |
| `hooks/check-pr-template.sh` | Shared PR template check |
| `hooks/pr-template-check-claude-code.sh` | PreToolUse envelope over the shared check |
| `skills/*` | Skills, including `hashiiiii-locale` |

The plugin also contains the `*-cursor.sh` hooks and `json-escape.sh`. Claude Code does not run these files.

## How locale reaches context

For each session, the SessionStart hook (`hooks/session-start-claude-code.sh`) prints this content:

1. The full contents of `AGENTS.md`
2. A `## Locale (resolved)` block with the five keys

The hook reads `cwd` from the SessionStart input. If the input has no valid `cwd`, the hook uses `CLAUDE_PROJECT_DIR`.

The scope resolver finds the Git repository from that directory. The first existing file wins as a whole:

1. `<absolute-git-dir>/rules-for-ai/LOCALE.md`
2. `<repo>/.rules-for-ai/LOCALE.md`
3. `$XDG_CONFIG_HOME/rules-for-ai/LOCALE.md` (default `~/.config/rules-for-ai/LOCALE.md`)
4. `$CLAUDE_PLUGIN_ROOT/LOCALE.default.md`
5. Inline `en_US` for all five keys

The locale layers do not merge. A root-level `LOCALE.md` is not part of this order.

Project instructions in `CLAUDE.md` or `AGENTS.md` take precedence over the resolved keys.

Use `hashiiiii-locale` to create or update a locale scope.
