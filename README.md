# Rules for AI
<img src="https://img.shields.io/badge/LICENSE-MIT-green">

Portable rules and skills for AI coding agents.

Write your rules once and carry them across Claude Code and Cursor as an installable, updatable plugin — no more copy-pasting the same instructions into every machine and repository. Language preferences for issues, pull requests, comments, logs, and test logs are resolved per user and overridden per project. Use it as is, or fork it and swap in your own rules.

## Contents

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Shared behavioral principles |
| `LOCALE.default.md` | Default language settings |
| `skills/` | Git, GitHub issue, pull request, and locale skills |
| `hooks/` | SessionStart hook (Claude Code) |
| `rules-for-ai.sh` | One-command installer for every platform × scope |
| `rules/` | Cursor always-on rule (`.mdc`) |
| `.claude-plugin/`, `.cursor-plugin/` | Plugin and marketplace manifests |

## Setup

One script installs, updates, and uninstalls everything. Pick a platform (`claude` | `cursor`) and a scope:

| Scope | Meaning |
|-------|---------|
| `user` | every project on this machine |
| `project` | one repo, shared with your team via git |
| `local` | one repo, just you, nothing committed |

Without cloning (run inside the target repo for `project` / `local`):

```sh
curl -fsSL https://raw.githubusercontent.com/hashiiiii/rules-for-ai/main/rules-for-ai.sh | sh -s -- install claude user
curl -fsSL https://raw.githubusercontent.com/hashiiiii/rules-for-ai/main/rules-for-ai.sh | sh -s -- install cursor project
```

From a clone:

```sh
./rules-for-ai.sh install claude project path/to/repo
./rules-for-ai.sh uninstall cursor user
```

Re-running `install` is how you update. `uninstall` removes exactly what install created.

### Claude Code notes

- Requires the `claude` CLI. Scopes map to `claude plugin ... --scope`: `user` writes `~/.claude/settings.json`, `project` writes the repo's `.claude/settings.json` (commit it — teammates only accept the trust prompt), `local` writes `.claude/settings.local.json` (Claude Code ignores it globally, so nothing is added to your repo's `.gitignore`).
- The SessionStart hook injects `AGENTS.md` and resolved locale keys each session.
- Installed at user scope but want it off in one repo? Add to that repo's `.claude/settings.json`:

```json
{ "enabledPlugins": { "rules-for-ai@hashiiiii": false } }
```

- Interactive alternative: `/plugin marketplace add hashiiiii/rules-for-ai` then `/plugin install rules-for-ai@hashiiiii`.
- `rules-for-ai.sh install claude project` writes the same pin block you can also add by hand to `.claude/settings.json`:

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

### Cursor notes

- `user` clones into `~/.cursor/plugins/local/` (restart Cursor afterwards). Teams/Enterprise can instead import the repo from the dashboard: Settings → Plugins → Import from Repo.
- `project` copies `rules/agents.mdc` into `.cursor/rules/` and the skills (minus `hashiiiii-locale`) into `.cursor/skills/`. Commit them — teammates need no install at all.
- `local` is `project` plus `.git/info/exclude` entries, so nothing shows up in `git status`.

> [!WARNING]
> Already enabled for Claude Code (`enabledPlugins`)? Cursor imports it from `~/.claude/plugins/` — do not also install at `cursor user` scope.

### Set Locale

For user-scope installs, set which locale the agent uses for `issues`, `pull requests`, `code comments`, `logs`, and `test logs`: run the `/hashiiiii-locale` skill.

For project/local installs, skip it — it writes user-level config. Put language policy in the target project's own `CLAUDE.md` / rules instead; project instructions override the resolved locale keys by design.

## Updates

Re-run the same `rules-for-ai.sh` line (or `curl ... | sh -s -- ...`) — every cell updates in place. Claude Code can also use `/plugin marketplace update hashiiiii`.

## Fork and customize

Fork, edit `AGENTS.md` and `skills/`, then install from your fork's URL instead of `hashiiiii/rules-for-ai`.

Skills are namespaced `hashiiiii-*`. Rename them to your own prefix; `grep -rl 'hashiiiii-' .` lists every file to update.

Also point `REPO` at your fork in `rules-for-ai.sh` and update `repository` in `.claude-plugin/plugin.json`.

## Releasing (maintainers)

1. Bump `version` in both plugin manifests in lockstep (CI enforces this)
2. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`

The release workflow verifies the tag matches the manifest version and creates the GitHub release.

## License

[MIT](LICENSE.md)
