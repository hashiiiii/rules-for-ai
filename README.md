# Rules for AI
<img src="https://img.shields.io/badge/LICENSE-MIT-green">

Portable rules and skills for AI coding agents.

Write your rules once and carry them across Claude Code and Cursor as an installable, updatable plugin — no more copy-pasting the same instructions into every machine and repository. Language preferences for issues, comments, logs, and test logs are resolved per user and overridden per project. Use it as is, or fork it and swap in your own rules.

## Contents

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Shared behavioral principles |
| `LOCALE.default.md` | Default language settings |
| `skills/` | Git, GitHub issues, and locale skills |
| `hooks/` | SessionStart hook (Claude Code) |
| `rules/` | Cursor always-on rule (`.mdc`) |
| `.claude-plugin/`, `.cursor-plugin/` | Plugin and marketplace manifests |

## Setup

### Claude Code

```
/plugin marketplace add hashiiiii/rules-for-ai
/plugin install rules-for-ai@hashiiiii
```

The SessionStart hook injects `AGENTS.md` and resolved locale keys each session.

To pin the plugin for a team repo, add to `.claude/settings.json`:

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

### Cursor

Cursor 2.5+ has its own plugin system. A `.cursor-plugin/plugin.json` manifest bundles rules, skills, commands, MCP servers, and hooks, and Cursor auto-discovers each from its default directory. This repo ships that manifest, so it installs as a Cursor plugin the same way it does in Claude Code: `rules/agents.mdc` applies as an always-on rule, and the `hashiiiii-*` skills load from `skills/`.

Cursor only recognizes rules written as `.mdc` files with frontmatter — a plain `.md` in `rules/` is ignored — which is why the rule ships as `rules/agents.mdc` (`alwaysApply: true`) rather than `.md`.

#### Cursor IDE

This repo is not on Cursor's public marketplace, so `cursor.com/marketplace` and the in-editor `/add-plugin` command won't find it by name. Install it one of two ways:

- Team marketplace (Teams/Enterprise): Dashboard → Settings → Plugins → Import from Repo, pointed at `https://github.com/hashiiiii/rules-for-ai`. The root `.cursor-plugin/marketplace.json` lists the plugin, so it then appears for the team to enable from the Customize panel (or via `/add-plugin`).
- Local install (any plan): clone under `~/.cursor/plugins/local/` and restart Cursor.

  ```
  git clone https://github.com/hashiiiii/rules-for-ai ~/.cursor/plugins/local/rules-for-ai
  ```

#### cursor-agent (CLI)

Cursor states plugins work across the IDE, CLI, and Cloud, so a plugin installed above is also available to `cursor-agent`. Manage it inside a session with the `/plugin` slash command, and inspect its MCP servers with `/mcp`.

Note that in Cursor the `hashiiiii-*` entries are skills: the agent discovers and runs them by name when relevant, rather than being typed as `/` slash commands the way they are in Claude Code. Cursor's own plugin slash commands are `/add-plugin` (IDE), `/plugin` (CLI), and `/mcp`.

Independently of the plugin system, `cursor-agent` already reads rules from a project's `.cursor/rules/*.mdc` and root `AGENTS.md` / `CLAUDE.md`, and respects `mcp.json`. So dropping this repo's `AGENTS.md` (or `rules/agents.mdc`) into a project applies the same rules to the CLI even without installing the plugin.

### Set Locale

After install, set which locale the agent uses for `issues`, `code comments`, `logs`, and `test logs`:

- Claude Code: run `/hashiiiii-locale`.
- Cursor: ask the agent to set your locale — it runs the `hashiiiii-locale` skill (Cursor invokes skills by name rather than as a typed `/` slash command).

The skill walks you through it — no manual config files needed.

## Updates

| Platform | Command |
|----------|---------|
| Claude Code | `/plugin marketplace update hashiiiii` |
| Cursor | Team marketplace UI (auto-refresh is periodic), or `git pull` for a local install |

## Fork and customize

Fork, edit `AGENTS.md` and `skills/`, then install from your fork's URL instead of `hashiiiii/rules-for-ai`.

Skills are namespaced `hashiiiii-*`. Rename them to your own prefix; `grep -rl 'hashiiiii-' .` lists every file to update.

## Releasing (maintainers)

1. Bump `version` in both plugin manifests in lockstep (CI enforces this)
2. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`

The release workflow verifies the tag matches the manifest version and creates the GitHub release.

## License

[MIT](LICENSE.md)
