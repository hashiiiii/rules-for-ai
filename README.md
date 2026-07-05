# Rules for AI

<img src="https://img.shields.io/badge/LICENSE-MIT-green">

My real-world rules and skills for AI coding agents — Claude Code and Cursor
CLI (cursor-agent) — packaged so any project can adopt them, under MIT.

This repository deploys nothing by itself. Projects take it in by copy or
`git submodule`; global (home-directory) deployment is handled by my
[dotfiles](https://github.com/hashiiiii/dotfiles), which pins this repository
as a submodule and symlinks it into `~/.claude` / `~/.cursor`. Machine-level
settings (Claude Code `settings.json`, MCP servers) live in dotfiles, not
here — this repository holds only what is portable across machines and
projects.

## Layout

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Behavioral principles shared by all agents |
| `skills/` | Agent Skills (`SKILL.md`), readable by both harnesses |

## Using in a project

Copy the files you want, or add the repository as a submodule and link the
rules to the project root:

```bash
git submodule add https://github.com/hashiiiii/rules-for-ai.git rules-for-ai
ln -s rules-for-ai/AGENTS.md AGENTS.md
ln -s AGENTS.md CLAUDE.md
```

Cursor CLI reads `AGENTS.md` / `CLAUDE.md` at the project root only, so the
root-level links are what make the rules take effect; Claude Code reads the
same files.

## License

[MIT](LICENSE.md)
