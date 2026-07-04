# Rules for AI

<img src="https://img.shields.io/badge/LICENSE-MIT-green">

My real-world configuration for AI coding agents — Claude Code and Cursor CLI
(cursor-agent) — published as is, under MIT.

This repository is the single source of truth: files here are symlinked into
`~/.claude` and `~/.cursor` by [mise](https://mise.jdx.dev)'s experimental
`dotfiles` feature.

## Layout

| Path | Deploys to | Purpose |
|------|------------|---------|
| `AGENTS.md` | `~/.claude/CLAUDE.md` | Behavioral principles shared by all agents |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code settings (model, permissions, hooks, plugins) |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Claude Code status line script |
| `skills/` | `~/.claude/skills`, `~/.cursor/skills` | Agent Skills (`SKILL.md`), one source for both harnesses |
| `cursor/mcp.json` | `~/.cursor/mcp.json` | cursor-agent global MCP servers (secret-free) |

## Install

With [mise](https://mise.jdx.dev):

```bash
git clone https://github.com/hashiiiii/rules-for-ai.git
cd rules-for-ai
mise dotfiles apply
```

Without mise, create the symlinks manually:

```bash
ln -s "$PWD/AGENTS.md"                    ~/.claude/CLAUDE.md
ln -s "$PWD/claude/settings.json"         ~/.claude/settings.json
ln -s "$PWD/claude/statusline-command.sh" ~/.claude/statusline-command.sh
ln -s "$PWD/skills"                       ~/.claude/skills
ln -s "$PWD/skills"                       ~/.cursor/skills
ln -s "$PWD/cursor/mcp.json"              ~/.cursor/mcp.json
```

## Notes

- **Cursor CLI has no global rules.** It reads `AGENTS.md` / `CLAUDE.md` at
  the project root only, so copy `AGENTS.md` (plus a `CLAUDE.md -> AGENTS.md`
  symlink) into each project. Claude Code picks the same content up globally
  via `~/.claude/CLAUDE.md`.
- **Skills are cross-harness.** Agent Skills (`SKILL.md`) are read by both
  Claude Code and cursor-agent; `skills/` feeds both through two symlinks.
- **No secrets.** `cursor/mcp.json` must stay token-free; anything secret
  belongs in environment variables or untracked local files.

## License

[MIT](LICENSE.md)
