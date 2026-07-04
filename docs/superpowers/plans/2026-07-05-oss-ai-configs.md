# OSS AI Configs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `rules-for-ai` the single source of truth for Claude Code / cursor-agent configuration, deployed by its own `mise.toml`, and remove those configs from `dotfiles`.

**Architecture:** Config files move from `dotfiles` (`.config/claude/`, `.config/cursor/`) into this repository under `claude/`, `cursor/`, and `skills/`. A new `mise.toml` `[dotfiles]` table symlinks them into `~/.claude` and `~/.cursor`. The switch happens apply-first, remove-second so the machine never has dangling symlinks.

**Tech Stack:** mise (experimental `dotfiles` feature), POSIX sh, JSON. No automated tests — this is a configuration repository; every task carries manual verification commands instead (spec decision).

**Spec:** `docs/superpowers/specs/2026-07-05-rules-for-ai-refresh-design.md`

## Global Constraints

- Commit messages: exactly one line, `<type>: <subject>`, English, imperative, lowercase first word, no trailing period, subject ≤ 50 characters. Types only from: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
- All documentation is English only. No `*_JA` files.
- No emojis anywhere.
- No secrets in any committed file (`cursor/mcp.json` must stay token-free).
- Work happens on branch `feat/oss-ai-configs` in `/Users/hashiiiii/workspace/rules-for-ai` (already checked out) and on a new branch in `/Users/hashiiiii/workspace/dotfiles` (Task 7).
- Task 6 (apply new deployment) MUST run before Task 7 (remove dotfiles entries).
- Do not push either repository; pushing is decided by the user after review.

## File Structure

```
rules-for-ai/
├── AGENTS.md                  # exists untracked — commit as-is (Task 1)
├── CLAUDE.md -> AGENTS.md     # exists untracked — commit as-is (Task 1)
├── .gitignore                 # exists untracked — commit as-is (Task 1)
├── claude/
│   ├── settings.json          # new file, edited copy of dotfiles version (Task 2)
│   └── statusline-command.sh  # copied from ~/.claude/statusline-command.sh (Task 2)
├── cursor/
│   └── mcp.json               # copied from dotfiles (Task 3)
├── skills/
│   └── git-conventions/
│       └── SKILL.md           # copied from dotfiles (Task 3)
├── mise.toml                  # new deployment definition (Task 4)
└── README.md                  # full rewrite (Task 5)

dotfiles/ (separate repo, Task 7)
├── mise.toml                  # remove 4 AI entries, keep ~/.claude/hooks
├── AGENTS.md                  # update ~/.claude note
├── README.md                  # add pointer to rules-for-ai
├── .config/claude/settings.json   # delete
├── .config/claude/skills/         # delete
└── .config/cursor/mcp.json        # delete
```

---

### Task 1: Finalize legacy removal and commit base files

The old Cursor IDE / Windsurf rule trees are already deleted in the working tree; `AGENTS.md`, `CLAUDE.md` (symlink), and `.gitignore` already exist untracked. This task turns that prepared state into two clean commits. `README.md` is left uncommitted — Task 5 rewrites it.

**Files:**
- Delete (finalize): `cursor/global/`, `cursor/local/`, `windsurf/global/`, `windsurf/local/`, `README_JA.md`
- Create (already on disk): `AGENTS.md`, `CLAUDE.md`, `.gitignore`

**Interfaces:**
- Produces: repo root `AGENTS.md` — every later task and the deployed `~/.claude/CLAUDE.md` symlink reference this exact path.

- [ ] **Step 1: Verify the expected working-tree state**

Run: `git status --short`
Expected: ` M README.md`, ` D README_JA.md`, ` D cursor/...` (4 files), ` D windsurf/...` (4 files), `?? .gitignore`, `?? AGENTS.md`, `?? CLAUDE.md`. If anything else appears, stop and report.

- [ ] **Step 2: Commit the deletions**

```bash
git add -u -- README_JA.md cursor windsurf
git commit -m "chore: remove legacy cursor and windsurf rules"
```

- [ ] **Step 3: Commit the base files**

```bash
git add .gitignore AGENTS.md CLAUDE.md
git commit -m "feat: add shared agents rules and gitignore"
```

- [ ] **Step 4: Verify only README.md remains dirty**

Run: `git status --short`
Expected: exactly ` M README.md`.

---

### Task 2: Add Claude Code settings and statusline script

**Files:**
- Create: `claude/settings.json`
- Create: `claude/statusline-command.sh` (copy of `~/.claude/statusline-command.sh`)

**Interfaces:**
- Consumes: nothing.
- Produces: `claude/settings.json` and `claude/statusline-command.sh` — Task 4 maps these paths in `mise.toml`; Task 5 lists them in the README table.

- [ ] **Step 1: Create `claude/settings.json`**

This is `/Users/hashiiiii/workspace/dotfiles/.config/claude/settings.json` with ONE change: the SessionStart hook command loses its hardcoded `/Users/hashiiiii` path and gains a file-existence guard, so machines without herdr get no failing hook. Full content:

```json
{
  "cleanupPeriodDays": 365,
  "attribution": {
    "commit": "",
    "pr": "",
    "sessionUrl": false
  },
  "permissions": {
    "allow": [],
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/*.pem)",
      "Read(**/*_rsa)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/credentials)",
      "Read(~/.config/gcloud/**)",
      "Read(~/.config/op/**)"
    ],
    "ask": [],
    "defaultMode": "auto"
  },
  "model": "claude-fable-5[1m]",
  "fallbackModel": [
    "claude-opus-4-8"
  ],
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "[ -f \"$HOME/.claude/hooks/herdr-agent-state.sh\" ] && bash \"$HOME/.claude/hooks/herdr-agent-state.sh\" session || true",
            "timeout": 10
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  },
  "enabledPlugins": {
    "code-simplifier@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": false,
    "security-guidance@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true
  },
  "outputStyle": "Explanatory",
  "language": "Japanese",
  "spinnerTipsEnabled": false,
  "alwaysThinkingEnabled": true,
  "effortLevel": "xhigh",
  "awaySummaryEnabled": true,
  "autoUpdatesChannel": "latest",
  "tui": "fullscreen",
  "skipDangerousModePermissionPrompt": true,
  "skipWorkflowUsageWarning": true,
  "preferredNotifChannel": "ghostty",
  "remoteControlAtStartup": true,
  "inputNeededNotifEnabled": true,
  "agentPushNotifEnabled": true,
  "skipAutoPermissionPrompt": true
}
```

- [ ] **Step 2: Copy the statusline script unchanged**

```bash
mkdir -p claude
cp /Users/hashiiiii/.claude/statusline-command.sh claude/statusline-command.sh
```

- [ ] **Step 3: Verify JSON validity and the absence of machine-specific paths**

Run: `jq -e . claude/settings.json > /dev/null && echo OK`
Expected: `OK`
Run: `grep -c '/Users/hashiiiii' claude/settings.json claude/statusline-command.sh; true`
Expected: `claude/settings.json:0` and `claude/statusline-command.sh:0`.

- [ ] **Step 4: Verify the only diff against the dotfiles original is the hook command**

Run: `diff <(jq -S . /Users/hashiiiii/workspace/dotfiles/.config/claude/settings.json) <(jq -S . claude/settings.json)`
Expected: exactly one changed line pair — the old `"command": "bash '/Users/hashiiiii/.claude/hooks/herdr-agent-state.sh' session"` vs the new guarded command.

- [ ] **Step 5: Commit**

```bash
git add claude/settings.json claude/statusline-command.sh
git commit -m "feat: add claude settings and statusline"
```

---

### Task 3: Add cursor MCP config and agent skills

**Files:**
- Create: `cursor/mcp.json` (verbatim copy)
- Create: `skills/git-conventions/SKILL.md` (verbatim copy)

**Interfaces:**
- Consumes: nothing.
- Produces: `cursor/mcp.json` and `skills/` — Task 4 maps these paths; `skills/` is a directory mapped whole (both `~/.claude/skills` and `~/.cursor/skills` point at it).

- [ ] **Step 1: Copy both sources verbatim**

```bash
mkdir -p cursor skills
cp /Users/hashiiiii/workspace/dotfiles/.config/cursor/mcp.json cursor/mcp.json
cp -R /Users/hashiiiii/workspace/dotfiles/.config/claude/skills/git-conventions skills/git-conventions
```

- [ ] **Step 2: Verify the copies are identical and token-free**

Run: `diff -r /Users/hashiiiii/workspace/dotfiles/.config/claude/skills/git-conventions skills/git-conventions && diff /Users/hashiiiii/workspace/dotfiles/.config/cursor/mcp.json cursor/mcp.json && echo IDENTICAL`
Expected: `IDENTICAL`
Run: `grep -iE 'token|key|secret' cursor/mcp.json; true`
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add cursor/mcp.json skills
git commit -m "feat: add cursor mcp config and skills"
```

---

### Task 4: Add mise deployment definition

**Files:**
- Create: `mise.toml`

**Interfaces:**
- Consumes: all paths created in Tasks 1-3 (`AGENTS.md`, `claude/settings.json`, `claude/statusline-command.sh`, `skills/`, `cursor/mcp.json`).
- Produces: the `[dotfiles]` table — Task 6 runs `mise dotfiles apply` against it; Task 5's README documents the same mapping.

- [ ] **Step 1: Create `mise.toml`**

```toml
#:tombi schema.strict = false

[settings]
experimental = true

# One source feeds both harnesses: Agent Skills (SKILL.md) are a cross-harness
# standard read by Claude Code (~/.claude/skills) and cursor-agent
# (~/.cursor/skills). Keep tokens OUT of cursor/mcp.json (it's committed).
[dotfiles]
"~/.claude/CLAUDE.md"             = "AGENTS.md"
"~/.claude/settings.json"         = "claude/settings.json"
"~/.claude/statusline-command.sh" = "claude/statusline-command.sh"
"~/.claude/skills"                = "skills"
"~/.cursor/skills"                = "skills"
"~/.cursor/mcp.json"              = "cursor/mcp.json"
```

- [ ] **Step 2: Verify mise parses it and sees all six mappings**

Run: `mise dotfiles status` (from the repository root)
Expected: six entries listed (`~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/statusline-command.sh`, `~/.claude/skills`, `~/.cursor/skills`, `~/.cursor/mcp.json`). Status values will show them as not yet applied / pointing elsewhere — that is expected before Task 6. The command must NOT error.

- [ ] **Step 3: Commit**

```bash
git add mise.toml
git commit -m "feat: add mise dotfiles deployment"
```

---

### Task 5: Rewrite README in English

**Files:**
- Modify: `README.md` (full replacement; the working tree already has an uncommitted stub)

**Interfaces:**
- Consumes: the layout from Tasks 1-4 (paths and deploy targets must match `mise.toml` exactly).
- Produces: user-facing documentation; nothing downstream consumes it.

- [ ] **Step 1: Replace `README.md` with exactly this content**

````markdown
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
````

- [ ] **Step 2: Verify the mapping table matches `mise.toml`**

Run: `grep -c '^"~/' mise.toml`
Expected: `6` (the six mapping lines; comment lines are excluded). Manually confirm each of the six targets appears once in the README table (the `skills/` row covers two targets).

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: rewrite readme for ai agent configs"
```

---

### Task 6: Switch this machine to the new deployment

Machine-state task; no commit. Existing targets are symlinks into `dotfiles` (`~/.claude/settings.json`, `~/.claude/skills`, `~/.cursor/skills`, `~/.cursor/mcp.json`), one real file (`~/.claude/statusline-command.sh`), and one absent path (`~/.claude/CLAUDE.md`). Sources for all of them remain safely in git, so removing the old targets is not destructive.

**Files:**
- Modify (filesystem, not git): symlinks under `~/.claude` and `~/.cursor`

**Interfaces:**
- Consumes: `mise.toml` from Task 4.
- Produces: live symlinks into this repository — Task 7 may only run after this task succeeds.

- [ ] **Step 1: Record the current state**

Run: `ls -la ~/.claude/settings.json ~/.claude/skills ~/.claude/statusline-command.sh ~/.cursor/skills ~/.cursor/mcp.json 2>&1; ls -la ~/.claude/CLAUDE.md 2>&1`
Expected: first five exist (four symlinks into `dotfiles`, one regular file); `~/.claude/CLAUDE.md` reports "No such file or directory".

- [ ] **Step 2: Apply from the repository root**

Run: `mise dotfiles apply -y` (in `/Users/hashiiiii/workspace/rules-for-ai`)
Expected: reports the six mappings applied. If mise refuses to replace an existing target, remove the old targets first — they are only links plus one file whose copy is already committed:

```bash
rm ~/.claude/settings.json ~/.claude/skills ~/.claude/statusline-command.sh ~/.cursor/skills ~/.cursor/mcp.json
mise dotfiles apply -y
```

- [ ] **Step 3: Verify every target resolves into this repository**

Run:
```bash
for t in ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/statusline-command.sh ~/.claude/skills ~/.cursor/skills ~/.cursor/mcp.json; do
  printf '%s -> %s\n' "$t" "$(readlink "$t")"
done
```
Expected: every line shows a path inside `/Users/hashiiiii/workspace/rules-for-ai/`.

- [ ] **Step 4: Verify with mise and smoke-test Claude Code**

Run: `mise dotfiles status`
Expected: all six entries reported as applied/linked.
Run: `claude -p "reply with exactly: ok" 2>&1 | tail -5`
Expected: output contains `ok` and no hook error lines (the guarded hook exits 0 whether or not herdr is present).

---

### Task 7: Remove AI configs from dotfiles

Runs in `/Users/hashiiiii/workspace/dotfiles`. Only safe AFTER Task 6 (targets no longer point here).

**Files:**
- Modify: `/Users/hashiiiii/workspace/dotfiles/mise.toml` (remove 4 `[dotfiles]` entries + their comments, keep `~/.claude/hooks`)
- Modify: `/Users/hashiiiii/workspace/dotfiles/AGENTS.md` (update the `~/.claude` note)
- Modify: `/Users/hashiiiii/workspace/dotfiles/README.md` (add pointer section)
- Delete: `.config/claude/settings.json`, `.config/claude/skills/`, `.config/cursor/mcp.json`

**Interfaces:**
- Consumes: Task 6's completed switch.
- Produces: a dotfiles branch ready for the user to merge.

- [ ] **Step 1: Create a branch**

```bash
cd /Users/hashiiiii/workspace/dotfiles
git switch -c refactor/move-ai-configs
```

- [ ] **Step 2: Edit `mise.toml`** — in the `[dotfiles]` table, delete these lines (two comment blocks and four mappings), keeping `"~/.claude/hooks"` and everything else:

```toml
# Agent Skills (SKILL.md) are a cross-harness standard: one source feeds both
# Claude Code and Cursor (cursor-agent reads ~/.cursor/skills/<name>/SKILL.md).
"~/.claude/settings.json" = ".config/claude/settings.json"
"~/.claude/skills"        = ".config/claude/skills"
"~/.cursor/skills"        = ".config/claude/skills"
# cursor-agent global MCP. Same JSON schema as Claude's mcpServers, but Claude's
# live in the monolithic ~/.claude.json (not symlinkable), so this mirrors the
# secret-free local servers only. Keep tokens OUT of this file (it's committed).
"~/.cursor/mcp.json"      = ".config/cursor/mcp.json"
```

The resulting AI-related region of the table is exactly:

```toml
"~/.claude/hooks"         = ".config/claude/hooks"
```

- [ ] **Step 3: Delete the moved files**

```bash
git rm .config/claude/settings.json
git rm -r .config/claude/skills
git rm .config/cursor/mcp.json
```

- [ ] **Step 4: Update `AGENTS.md`** — replace this line:

```markdown
- **`~/.claude`** is not whole-directory symlinked (runtime/secrets); only `.config/claude/settings.json` and `hooks/`.
```

with:

```markdown
- **`~/.claude`** is not whole-directory symlinked (runtime/secrets); only `hooks/` lives here. Agent configs (settings, skills, MCP) come from [rules-for-ai](https://github.com/hashiiiii/rules-for-ai).
```

- [ ] **Step 5: Update `README.md`** — insert this section between "Re-converge" and the closing link list:

````markdown
## AI agent configs

Claude Code / cursor-agent configs live in
[rules-for-ai](https://github.com/hashiiiii/rules-for-ai) and deploy
themselves:

```bash
git clone https://github.com/hashiiiii/rules-for-ai.git ~/workspace/rules-for-ai
cd ~/workspace/rules-for-ai && mise dotfiles apply
```
````

- [ ] **Step 6: Verify remaining dotfiles mappings still apply cleanly**

Run: `mise dotfiles status` (in `/Users/hashiiiii/workspace/dotfiles`)
Expected: no AI entries besides `~/.claude/hooks`; no errors; `~/.claude/hooks` still linked.
Run: `readlink ~/.claude/hooks`
Expected: `/Users/hashiiiii/workspace/dotfiles/.config/claude/hooks`

- [ ] **Step 7: Commit**

```bash
git add mise.toml AGENTS.md README.md
git commit -m "refactor: move ai agent configs to rules-for-ai"
```

(The `git rm` deletions from Step 3 are already staged and land in this same commit.)

---

### Task 8: Final verification

No file changes; confirms the spec's Verification section end to end.

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: Both repos clean and on their branches**

Run: `git -C /Users/hashiiiii/workspace/rules-for-ai status --short --branch && git -C /Users/hashiiiii/workspace/dotfiles status --short --branch`
Expected: `## feat/oss-ai-configs` with a clean tree (the `docs/` spec and plan are committed); `## refactor/move-ai-configs` with a clean tree.

- [ ] **Step 2: Symlink audit**

Run the readlink loop from Task 6 Step 3 again, plus `readlink ~/.claude/hooks`.
Expected: six targets → `rules-for-ai`, hooks → `dotfiles`.

- [ ] **Step 3: Harness smoke tests**

Run: `claude -p "reply with exactly: ok" 2>&1 | tail -5`
Expected: `ok`, no hook or settings errors.
Run: `agent --list-models 2>&1 | head -5`
Expected: model list prints (cursor-agent starts and reads its config without error).

- [ ] **Step 4: Report to the user**

Summarize: what moved, both branch names, and that pushing/merging (and the interactive checks — statusline rendering, skills visible in a real session) are theirs to do.
