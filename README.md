# Rules for AI

Portable rules and skills for AI coding agents.

## Contents

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Shared behavioral principles |
| `LOCALE.default.md` | Default language settings (fallback) |
| `LOCALE.md.example` | Sample for project-root `LOCALE.md` |
| `skills/hashiiiii-git/` | Git conventions |
| `skills/hashiiiii-issues/` | GitHub issue body structure |
| `skills/hashiiiii-locale/` | Locale setup and updates |
| `hooks/` | Claude Code SessionStart hook (injects `AGENTS.md` + resolved locale) |
| `rules/` | Cursor always-on rules copy (`rules/agents.md`, mirrors `AGENTS.md`) |
| `.claude-plugin/` | Claude Code plugin + marketplace manifests |
| `.codex-plugin/` | Codex plugin manifest |
| `.cursor-plugin/` | Cursor plugin manifest |

## Install as a plugin

### Claude Code

```
/plugin marketplace add hashiiiii/rules-for-ai
/plugin install rules-for-ai@rules-for-ai
```

For a team project, commit this to the consuming repo's `.claude/settings.json` so cloners get the plugin after a one-time trust prompt:

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

Once installed, a SessionStart hook injects `AGENTS.md` plus the resolved locale table into every session automatically — no extra step.

### Codex

```
codex plugin marketplace add hashiiiii/rules-for-ai
```

Then install the plugin from `/plugins`.

For always-on rules, Codex plugins do not yet ship a hook in this release, so run this one-time step per machine:

```bash
cat AGENTS.md >> ~/.codex/AGENTS.md
```

(Verified 2026-07-05: a Codex plugin *can* inject always-on context at session start via a `SessionStart` hook, mechanically equivalent to Claude Code's — implementing that hook is a planned follow-up, not part of this release.)

### Cursor

Import `https://github.com/hashiiiii/rules-for-ai` via a team marketplace. `rules/agents.md` is auto-discovered as an always-applied rule once imported.

If your setup does not support marketplace import, fall back to a local path: clone the repo under `~/.cursor/plugins/local/`.

## Locale

Language settings resolve per artifact, per row — the first layer with a value for that row wins:

1. Project `LOCALE.md` (project root)
2. `~/.config/rules-for-ai/LOCALE.md` (user level; respects `$XDG_CONFIG_HOME`)
3. Bundled `LOCALE.default.md` (fallback, all `en_US`)

Four artifacts are configurable independently: Issues, Code comments, Log messages, Test log messages.

On Claude Code, the SessionStart hook resolves and injects this table every session. If no user-level file exists yet, onboarding fires once: the agent asks which language to use for each artifact and saves the answer with the `hashiiiii-locale` skill (accepting the defaults still records the choice, so the prompt does not repeat).

On Codex and Cursor, there is no hook, so resolution is model-driven: run the `hashiiiii-locale` skill, or create `~/.config/rules-for-ai/LOCALE.md` manually, following the same three-layer order.

No per-project `LOCALE.md` is needed unless you want to override the user-level (or default) setting for that project.

## Receiving updates

- **Claude Code**: checked at startup; auto-update is off by default for third-party marketplaces. Update manually with `/plugin marketplace update rules-for-ai`, or enable auto-update if you prefer.
- **Codex**: run `codex plugin marketplace upgrade`.
- **Cursor**: imported repos auto-refresh periodically; refresh manually from the marketplace UI if you need it sooner.

## Fork and customize

Fork this repository, edit `AGENTS.md` and `skills/` to fit your team, then run the same install commands from the "Install as a plugin" section above against your fork's URL instead of `hashiiiii/rules-for-ai`. A fork is its own marketplace — no coordination with upstream required.

## Manual alternative (submodule)

**Recommended without a plugin manager:** fork this repository, add your fork as a submodule at `.rules-for-ai` (hidden — the project root only needs the symlinks below), and link at the project root. That gives you a place to customize `AGENTS.md` and `skills/` while still pulling upstream updates when you want them.

```bash
# Fork https://github.com/hashiiiii/rules-for-ai on GitHub, then:
git submodule add https://github.com/${YOUR_USER}/rules-for-ai.git .rules-for-ai
ln -s .rules-for-ai/AGENTS.md AGENTS.md
ln -s AGENTS.md CLAUDE.md
cp .rules-for-ai/LOCALE.md.example LOCALE.md   # optional; skip to use defaults
```

To sync upstream changes into your fork:

```bash
cd .rules-for-ai
git remote add upstream https://github.com/hashiiiii/rules-for-ai.git   # once
git fetch upstream && git merge upstream/main
cd ..
git add .rules-for-ai && git commit -m "Update rules-for-ai submodule"
```

**Alternative:** copy the files you need into your project if you prefer not to use submodules.

Both harnesses read `AGENTS.md` / `CLAUDE.md` at the project root. Install skills from `skills/` into your agent's skills directory as needed.

Language settings (issues, code comments, logs) live in `LOCALE.md` at the project root. Without one, agents fall back to `LOCALE.default.md`, which defaults everything to English. Commit `LOCALE.md` at the project root — it lives outside the submodule, so `git submodule update` never touches it.

## Releasing (maintainers)

```bash
scripts/release.sh 0.2.0
```

Bumps the `version` field in all three manifests (`.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json`) in lockstep, commits, tags `v0.2.0`, and pushes.

Machine-level settings (Claude Code `settings.json`, MCP servers) and global home-directory setup live in [dotfiles](https://github.com/hashiiiii/dotfiles), not here — this repository holds only what is portable across machines and projects.

## License

[MIT](LICENSE.md)
