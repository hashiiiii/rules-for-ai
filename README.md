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

## Use in a project

**Recommended:** fork this repository, add your fork as a submodule at `.rules-for-ai` (hidden — the project root only needs the symlinks below), and link at the project root. That gives you a place to customize `AGENTS.md` and `skills/` while still pulling upstream updates when you want them.

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

Machine-level settings (Claude Code `settings.json`, MCP servers) and global home-directory setup live in [dotfiles](https://github.com/hashiiiii/dotfiles), not here — this repository holds only what is portable across machines and projects.

## License

[MIT](LICENSE.md)
