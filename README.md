# Rules for AI
<img src="https://img.shields.io/badge/LICENSE-MIT-green">

Portable rules and skills for AI coding agents.

Write your rules once and carry them across Claude Code, Codex, and Cursor as an installable, updatable plugin — no more copy-pasting the same instructions into every machine and repository. Language preferences for issues, comments, logs, and test logs are resolved per user and overridden per project. Use it as is, or fork it and swap in your own rules.

## Contents

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Shared behavioral principles |
| `LOCALE.default.md` | Default language settings |
| `skills/` | Git, GitHub issues, and locale skills |
| `hooks/` | SessionStart hook (Claude Code) |
| `rules/` | Cursor always-on rules |
| `.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/` | Plugin manifests |

## Install

### Claude Code

```
/plugin marketplace add hashiiiii/rules-for-ai
/plugin install rules-for-ai@rules-for-ai
```

The SessionStart hook injects `AGENTS.md` and resolved locale keys each session.

To pin the plugin for a team repo, add to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "rules-for-ai": {
      "source": { "source": "github", "repo": "hashiiiii/rules-for-ai" }
    }
  },
  "enabledPlugins": { "rules-for-ai@rules-for-ai": true }
}
```

### Codex

```
codex plugin marketplace add hashiiiii/rules-for-ai
```

Install from `/plugins`. Until a SessionStart hook ships, append rules once per machine:

```bash
curl -fsSL https://raw.githubusercontent.com/hashiiiii/rules-for-ai/main/AGENTS.md >> ~/.codex/AGENTS.md
```

### Cursor

Import `https://github.com/hashiiiii/rules-for-ai` via a team marketplace. `rules/agents.md` is auto-discovered as an always-applied rule.

Without marketplace support, clone under `~/.cursor/plugins/local/`.

## Locale

Resolution order (first existing file wins; layers do not merge):

1. `~/.config/rules-for-ai/LOCALE.md` (respects `$XDG_CONFIG_HOME`)
2. Bundled `LOCALE.default.md`

Four keys: `issues`, `comments`, `logs`, `test-logs` (`key=value` lines, POSIX locale tags).

Project-level language policy belongs in that project's `CLAUDE.md` / `AGENTS.md` and overrides resolved keys.

On Claude Code, the hook resolves and injects locale keys. On first run with no user file, the `hashiiiii-locale` skill runs once to set preferences.

On Codex and Cursor, run `hashiiiii-locale` or create `~/.config/rules-for-ai/LOCALE.md` manually.

## Updates

| Platform | Command |
|----------|---------|
| Claude Code | `/plugin marketplace update rules-for-ai` |
| Codex | `codex plugin marketplace upgrade` |
| Cursor | Marketplace UI (auto-refresh is periodic) |

## Fork and customize

Fork, edit `AGENTS.md` and `skills/`, then install from your fork's URL instead of `hashiiiii/rules-for-ai`.

Skills are namespaced `hashiiiii-*`. Rename them to your own prefix; `grep -rl 'hashiiiii-' .` lists every file to update.

## Releasing (maintainers)

1. Bump `version` in all three plugin manifests in lockstep (CI enforces this)
2. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`

The release workflow verifies the tag matches the manifest version and creates the GitHub release.

## License

[MIT](LICENSE.md)
