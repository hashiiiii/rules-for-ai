# Rules for AI

<img src="https://img.shields.io/badge/LICENSE-MIT-green">

My real-world configuration for AI coding agents — Claude Code and Cursor CLI
(cursor-agent) — packaged so any project can adopt it, under MIT.

This repository deploys nothing by itself. Projects take it in by copy or
`git submodule`; global (home-directory) deployment is handled by my
[dotfiles](https://github.com/hashiiiii/dotfiles), which pins this repository
as a submodule and symlinks it into `~/.claude` / `~/.cursor`.

## Layout

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Behavioral principles shared by all agents |
| `claude/settings.json` | Claude Code settings (model, permissions, hooks, plugins) |
| `claude/statusline-command.sh` | Claude Code status line script |
| `skills/` | Agent Skills (`SKILL.md`), readable by both harnesses |
| `cursor/mcp.json` | cursor-agent MCP servers (secret-free) |

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

## Notes

- These are my live settings. Review `claude/settings.json` before adopting —
  it reduces permission prompting and sets Japanese output, among other
  personal choices.
- `cursor/mcp.json` must stay token-free; anything secret belongs in
  environment variables or untracked local files.

## License

[MIT](LICENSE.md)
