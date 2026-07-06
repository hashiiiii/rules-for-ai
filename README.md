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
| `rules/` | Cursor always-on rules |
| `.claude-plugin/`, `.cursor-plugin/` | Plugin manifests |

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

Import `https://github.com/hashiiiii/rules-for-ai` via a team marketplace. `rules/agents.md` is auto-discovered as an always-applied rule.

Without marketplace support, clone under `~/.cursor/plugins/local/`.

### Set Locale

After install, run `/hashiiiii-locale` to set which locale the agent uses for `issues`, `code comments`, `logs`, and `test logs`. The skill walks you through it — no manual config files needed.

## Updates

| Platform | Command |
|----------|---------|
| Claude Code | `/plugin marketplace update hashiiiii` |
| Cursor | Marketplace UI (auto-refresh is periodic) |

## Fork and customize

Fork, edit `AGENTS.md` and `skills/`, then install from your fork's URL instead of `hashiiiii/rules-for-ai`.

Skills are namespaced `hashiiiii-*`. Rename them to your own prefix; `grep -rl 'hashiiiii-' .` lists every file to update.

## Releasing (maintainers)

1. Bump `version` in both plugin manifests in lockstep (CI enforces this)
2. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`

The release workflow verifies the tag matches the manifest version and creates the GitHub release.

## License

[MIT](LICENSE.md)
