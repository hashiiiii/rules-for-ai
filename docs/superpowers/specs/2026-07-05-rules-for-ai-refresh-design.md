# rules-for-ai Refresh — Design

Date: 2026-07-05
Status: Approved

## Goal

Turn `rules-for-ai` into the single source of truth for the author's AI agent
configurations (Claude Code and Cursor CLI / cursor-agent), published as OSS.
The repository previously held Cursor / Windsurf rule files, which are
obsolete and already deleted from the working tree.

The configurations currently live in the public `dotfiles` repository
(`.config/claude/`, `.config/cursor/`) and are symlinked into place by mise's
experimental `[dotfiles]` feature. After this change, the files move here and
this repository deploys itself; `dotfiles` drops its AI-related entries.

## Non-Goals

- Turning the repository into a generic template / best-practice collection.
  It publishes the author's real, working configuration.
- Bilingual documentation. All documentation is English only; the previous
  `*_JA` file convention is retired.
- Managing `~/.claude/hooks`. Its only content is generated and overwritten
  by herdr (a third-party tool); it stays in `dotfiles`.
- Automated tests. Verification is manual (see Verification).

## Decisions (with rationale)

1. **Operating model: move, not copy.** The files move from `dotfiles` to
   this repository, and `dotfiles`' mise mappings for them are removed.
   A curated copy was rejected because dual maintenance drifts.
2. **Deployment: self-contained via mise.** This repository carries its own
   `mise.toml` with a `[dotfiles]` section; `mise dotfiles apply` run at the
   repository root creates the symlinks. Verified locally: `mise dotfiles`
   applies the `[dotfiles]` table of the current config root. A git
   submodule inside `dotfiles` and committed absolute-path symlinks were
   rejected (update friction; machine-dependent paths).
3. **`AGENTS.md` is deployed globally for Claude Code only.** The Cursor CLI
   reads rules from the project root (`AGENTS.md`, `CLAUDE.md`) and
   `.cursor/rules` — it has no user-level global rules location
   (cursor.com/docs/cli/using, checked 2026-07-05). Projects keep the
   per-project `AGENTS.md` + `CLAUDE.md -> AGENTS.md` pattern; this
   repository is the canonical source to copy from.
4. **`skills/` sits at the repository top level.** Agent Skills (`SKILL.md`)
   are a cross-harness standard; one source directory feeds both
   `~/.claude/skills` and `~/.cursor/skills`, continuing the design already
   documented in `dotfiles`' mise.toml.

## Repository Layout

```
rules-for-ai/
├── AGENTS.md                  # behavioral principles; also this repo's own instructions
├── CLAUDE.md -> AGENTS.md     # existing symlink, kept
├── claude/
│   ├── settings.json          # moved from dotfiles .config/claude/settings.json
│   └── statusline-command.sh  # adopted from ~/.claude (previously unmanaged)
├── cursor/
│   └── mcp.json               # moved from dotfiles .config/cursor/mcp.json
├── skills/
│   └── git-conventions/
│       └── SKILL.md           # moved from dotfiles .config/claude/skills/
├── mise.toml                  # new: [dotfiles] deployment definition
├── README.md                  # rewritten in English
├── LICENSE.md                 # MIT, unchanged
└── .gitignore                 # unchanged
```

The deletion of the old `cursor/` and `windsurf/` rule trees and
`README_JA.md` (already deleted in the working tree) is finalized in this
change. Note the new `cursor/` directory holds configuration for
cursor-agent, unrelated to the deleted Cursor IDE rule files.

## Deployment (mise.toml)

```toml
[settings]
experimental = true

[dotfiles]
"~/.claude/CLAUDE.md"             = "AGENTS.md"
"~/.claude/settings.json"         = "claude/settings.json"
"~/.claude/statusline-command.sh" = "claude/statusline-command.sh"
"~/.claude/skills"                = "skills"
"~/.cursor/skills"                = "skills"
"~/.cursor/mcp.json"              = "cursor/mcp.json"
```

`~/.claude/CLAUDE.md` is a new deployment (no global memory existed before).
The README documents the same mapping as a table with manual `ln -s`
instructions for users without mise.

## File Adjustments During the Move

- **`claude/settings.json`** — replace the hardcoded
  `/Users/hashiiiii/.claude/hooks/herdr-agent-state.sh` in the SessionStart
  hook with a `$HOME`-based path, and guard it with a file-existence check so
  environments without herdr (any OSS consumer) do not get a failing hook on
  every session start. Target shape:
  `[ -f "$HOME/.claude/hooks/herdr-agent-state.sh" ] && bash "$HOME/.claude/hooks/herdr-agent-state.sh" session || true`
- **`claude/statusline-command.sh`** — adopted as-is; its only dependency is
  `jq` and it contains no machine-specific paths.
- **`skills/git-conventions/SKILL.md`** — moved unchanged.
- **`cursor/mcp.json`** — moved unchanged; it is secret-free by design
  (tokens must never be committed to it).

## dotfiles-Side Changes (separate repository, same effort)

- Remove four `[dotfiles]` entries from `mise.toml`:
  `~/.claude/settings.json`, `~/.claude/skills`, `~/.cursor/skills`,
  `~/.cursor/mcp.json`. Keep `~/.claude/hooks`.
- Delete `.config/claude/settings.json`, `.config/claude/skills/`,
  `.config/cursor/mcp.json`.
- Update `dotfiles`' `AGENTS.md` note about `~/.claude` management to point
  at rules-for-ai.
- Document the new setup step (clone rules-for-ai, run
  `mise dotfiles apply`) where `dotfiles` describes machine setup.

Ordering: apply the rules-for-ai deployment first, then remove the dotfiles
entries, so the machine never has dangling symlinks.

## README Outline (English)

1. What this is: the author's real Claude Code / cursor-agent configuration,
   published as OSS under MIT.
2. Layout and deployment mapping table (file → target → purpose).
3. Install: `mise dotfiles apply`, plus manual symlink instructions.
4. Skills: cross-harness `SKILL.md` standard, one source for both harnesses.
5. Note: Cursor CLI has no global rules; copy `AGENTS.md` per project.

## Verification

- `mise dotfiles status` at the repository root shows all six mappings
  applied.
- `~/.claude/settings.json`, `~/.claude/skills`, `~/.cursor/skills`,
  `~/.cursor/mcp.json`, `~/.claude/CLAUDE.md`,
  `~/.claude/statusline-command.sh` resolve to files in this repository.
- Launch Claude Code: settings load, the `git-conventions` skill is listed,
  the statusline renders, and a session with no herdr environment starts
  without hook errors.
- Launch cursor-agent: MCP servers from `mcp.json` are available and
  `~/.cursor/skills` resolves.
