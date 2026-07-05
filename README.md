# Rules for AI

Portable rules and skills for AI coding agents.

## Contents

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Shared behavioral principles |
| `LOCALE.default.md` | Default language settings (fallback) |
| `LOCALE.md.example` | Sample for project-root `LOCALE.md` |
| `skills/hashiiiii-git/` | Branch and commit conventions |
| `skills/hashiiiii-issues/` | GitHub issue body structure |

## Use in a project

Copy what you need, or add as a submodule and link at the project root:

```bash
git submodule add https://github.com/hashiiiii/rules-for-ai.git rules-for-ai
ln -s rules-for-ai/AGENTS.md AGENTS.md
ln -s AGENTS.md CLAUDE.md
cp rules-for-ai/LOCALE.md.example LOCALE.md   # optional; skip to use defaults
```

Both harnesses read `AGENTS.md` / `CLAUDE.md` at the project root. Install skills from `skills/` into your agent's skills directory as needed.

Language settings (issues, code comments, logs) live in `LOCALE.md` at the project root. Without one, agents fall back to `LOCALE.default.md`, which defaults everything to English. Submodule users only need to commit a `LOCALE.md` at the project root — it lives outside the submodule, so `git submodule update` never touches it.

Machine-level settings (Claude Code `settings.json`, MCP servers) and global home-directory setup live in [dotfiles](https://github.com/hashiiiii/dotfiles), not here — this repository holds only what is portable across machines and projects.

## License

[MIT](LICENSE.md)
