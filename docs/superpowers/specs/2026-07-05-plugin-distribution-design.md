# Plugin Distribution Design

Date: 2026-07-05
Status: Approved (brainstorming session)
Revised: 2026-07-05 — dropped the project-level LOCALE layer; project
language policy now lives in the consuming project's own instruction file
(see "Locale resolution and onboarding")

## Background

This repository is currently consumed via a git submodule at `.rules-for-ai`
plus symlinks (`AGENTS.md`, `CLAUDE.md`) at the consumer's project root.
That works, but installation is manual and updates require git operations in
every consuming project.

Claude Code, Codex, and Cursor all support plugins as a distribution unit,
and all three read skills in the Agent Skills standard format (`SKILL.md`).
Packaging this repository as a plugin makes installation a one-time command,
makes updates a version bump, and keeps per-project opt-in.

## Goals

- Install with one command per tool; no per-project file placement required
- Per-project opt-in stays possible
- Always-on rules (`AGENTS.md` principles) reach the model at session start
  with the strongest guarantee each tool offers
- Locale preferences work without per-project files; all four artifacts
  (Issues, Code comments, Log messages, Test log messages) are individually
  configurable, because locales may differ per artifact
- Updates propagate through each tool's standard mechanism via explicit
  semver bumps
- Forking the repository for customization remains a first-class path
- The existing submodule + symlink path keeps working

## Non-goals / Out of scope

- Splitting into multiple repositories (content repo + per-tool plugin repos)
- A build step that generates per-tool artifacts from a `src/` tree
- Listing on the reviewed public Cursor Marketplace (direct GitHub import is
  the initial path; listing is a later decision)
- Machine-level settings (they live in dotfiles, not here)

## Decisions

| Topic | Decision |
|-------|----------|
| Audience | The author plus unspecified public users; forks are first-class |
| Tool coverage | Claude Code, Codex, and Cursor from the first release |
| Repo structure | Single repo, three thin manifests over one content tree |
| Always-on rules | Best mechanism per tool (see table below) |
| Locale storage | `~/.config/rules-for-ai/LOCALE.md` (user level), bundled `LOCALE.default.md` (fallback); no project-level file |
| Project-level overrides | Removed. A project-root `LOCALE.md` confuses collaborators who do not use the plugin, and keeping it private forces a `.gitignore` entry in the consuming repo. Project language policy is written as natural-language instructions in that project's `CLAUDE.md` / `AGENTS.md`, which override the resolved locale keys |
| Locale onboarding | Auto-starts on the first Claude Code session when no user-level file exists |
| Update policy | Explicit semver bumps; the three manifests stay in lockstep |
| Skill names | Keep `hashiiiii-` prefix (`hashiiiii-git`, `hashiiiii-issues`, new `hashiiiii-locale`) |

## Architecture

```
rules-for-ai/
├── .claude-plugin/
│   ├── plugin.json          # name, version (semver), description
│   └── marketplace.json     # the repo doubles as its own marketplace
├── .codex-plugin/
│   └── plugin.json          # Codex manifest
├── .cursor-plugin/
│   └── plugin.json          # Cursor manifest
├── skills/                  # Agent Skills standard; shared by all tools
│   ├── hashiiiii-git/SKILL.md
│   ├── hashiiiii-issues/SKILL.md
│   └── hashiiiii-locale/SKILL.md    # new: locale setup and updates
├── hooks/
│   ├── hooks.json           # SessionStart registration (Claude Code)
│   └── session-start.sh     # injects always-on rules + resolved locale
├── rules/
│   └── agents.md            # Cursor always-on rules (exact copy of AGENTS.md)
├── scripts/
│   └── release.sh           # lockstep version bump + tag + push
├── .github/workflows/
│   └── ci.yml               # tests, shellcheck, drift and lockstep checks
├── AGENTS.md                # single source of truth for always-on rules
├── LOCALE.default.md        # bundled fallback (all en_US)
└── README.md                # install/update/fork/submodule instructions
```

Component responsibilities:

| Component | Responsibility | Consumer |
|-----------|----------------|----------|
| `AGENTS.md` | Always-on rules, single source of truth; the only file to edit | hook (read at runtime), submodule users (symlink) |
| `hooks/session-start.sh` | Read `AGENTS.md`, resolve locale, emit onboarding instruction when unset | Claude Code |
| `rules/agents.md` | Cursor-consumable copy of the always-on rules; CI enforces equality | Cursor |
| `skills/*` | Task-scoped conventions plus locale management | all three tools |
| Three manifests | Distribution metadata only; no logic | each tool |

## Locale resolution and onboarding

`session-start.sh` runs on every Claude Code session start (startup, resume,
clear, compact):

1. Read `${CLAUDE_PLUGIN_ROOT}/AGENTS.md` (always-on rules).
2. Resolve the locale keys — the first existing file wins as a whole
   (layers never merge):
   a. `~/.config/rules-for-ai/LOCALE.md` (user)
   b. `${CLAUDE_PLUGIN_ROOT}/LOCALE.default.md` (bundled)
3. If (a) does not exist, append an onboarding instruction: ask the user for
   locale preferences at the start of the session and save them with the
   `hashiiiii-locale` skill.
4. Emit always-on rules + the resolved locale keys (+ onboarding
   instruction, when applicable) to stdout for context injection.

State is a single file: the existence of `~/.config/rules-for-ai/LOCALE.md`
means "configured". When the user accepts the defaults, `hashiiiii-locale`
writes the default keys to that path anyway, so the choice is recorded and
onboarding never fires again. No separate marker file.

There is deliberately no project-level LOCALE layer. A project-root
`LOCALE.md` is a bare key=value file whose purpose is opaque to
collaborators who do not use the plugin, and keeping it private forces a
`.gitignore` entry in the consuming repo — both outcomes pollute repos this
plugin does not own. A project-specific language policy is an ordinary
project instruction instead: written in natural language in that project's
`CLAUDE.md` / `AGENTS.md` (e.g. "Write issues in English"), self-explanatory
to every reader, and injected by every harness as top-priority instructions.
The rules injected by this plugin state the precedence explicitly: project
instructions override the resolved locale keys. A shell test asserts that a
project-root `LOCALE.md` is ignored, so the removed layer cannot silently
come back.

`hashiiiii-locale` skill:

- Interactive onboarding asks about each of the four artifacts individually
  (Issues, Code comments, Log messages, Test log messages), since locales
  may differ per artifact.
- Argument forms: a single tag (`ja_JP`) applies to all four rows; key=value
  pairs (`issues=ja_JP comments=ja_JP logs=en_US test-logs=en_US`) set rows
  individually. Keys map to artifacts as: `issues` = Issues, `comments` =
  Code comments, `logs` = Log messages, `test-logs` = Test log messages.
- Writes only the user-level file. When the user asks for a
  project-specific policy, the skill directs them to write it as plain
  instructions in that project's `CLAUDE.md` / `AGENTS.md` instead.
- Validates key names, creates `~/.config/rules-for-ai/` when missing, and
  writes atomically (temp file + `mv`).

Codex and Cursor have no hook, so their path stays model-driven: the locale
sections inside the skills (`hashiiiii-issues`, etc.) instruct the model to
read the same two-layer chain. The guarantee is weaker (model-driven vs
mechanical injection), but the resolution order is identical everywhere.
Onboarding only exists on Claude Code; Codex/Cursor users run the
`hashiiiii-locale` skill or create the file manually.

## Always-on rule injection per tool

| Tool | Mechanism | Guarantee |
|------|-----------|-----------|
| Claude Code | SessionStart hook output injected into context | Mechanical |
| Cursor | `rules/agents.md` auto-discovered as an always-applied rule | Mechanical |
| Codex | Verified 2026-07-05: injection is possible via a plugin-bundled SessionStart hook (see Risks and open questions); implementing it is a follow-up issue. Until then the README documents a one-time append of the rules to `~/.codex/AGENTS.md` | Manual one-time (hook promotion pending) |

`rules/agents.md` is an exact byte-for-byte copy of `AGENTS.md`; CI runs
`diff` to catch drift.

## Installation paths

- Claude Code: `/plugin marketplace add hashiiiii/rules-for-ai`, then
  `/plugin install`. For team projects, the consuming repo may commit
  `.claude/settings.json` with `extraKnownMarketplaces` + `enabledPlugins`
  so cloners get the plugin after a trust prompt (README includes the
  snippet).
- Codex: `codex plugin marketplace add hashiiiii/rules-for-ai`, then install
  from `/plugins`.
- Cursor: import the GitHub repo through a team marketplace. Public
  marketplace listing is out of scope initially.
- Forks: every command above works against the fork URL; a fork is its own
  marketplace.
- Submodule + symlink: kept in the README as the manual alternative.

## Release and updates

- The `version` fields in all three manifests are always identical
  (lockstep semver).
- `scripts/release.sh` bumps all three manifests, creates `git tag vX.Y.Z`,
  and pushes.
- CI verifies the three versions match, so a partial bump fails fast.
- Propagation: Claude Code checks at startup (auto-update is off by default
  for third-party marketplaces; users may enable it or run
  `/plugin marketplace update`); Codex users run
  `codex plugin marketplace upgrade`; Cursor auto-refreshes imported repos
  (roughly every 10 minutes) or refreshes manually. The README documents
  "how updates reach you" per tool.

## Error handling

- `session-start.sh` never breaks session start: always exit 0.
- A missing layer falls through to the next; the first existing LOCALE
  file wins as a whole (layers never merge). The bundled default lives in
  the plugin cache, so the chain always terminates.
- LOCALE files are machine-written by the hashiiiii-locale skill, so the
  hook trusts the strict key=value format instead of validating it. Only
  the four fixed keys are picked up; locale tags are passed through without
  validation — not breaking the session takes priority over catching typos.

## Testing

Per repository conventions: no mocks or stubs, comments prioritized in
tests, test log messages in English.

- Shell tests for `session-start.sh` against real temp directories with real
  locale files. Cases: no config at all (defaults + onboarding instruction),
  user config only, a project-root `LOCALE.md` present but ignored
  (regression guard for the removed project layer).
- CI (GitHub Actions): run shell tests, shellcheck, `diff AGENTS.md
  rules/agents.md`, manifest version lockstep check.
- End-to-end verification: add the repo as a local-path marketplace, install
  the plugin, open a fresh session, and confirm both the injected content
  and onboarding firing. Documented as steps in the implementation plan.

## Migration steps

1. Commit the current uncommitted refinements (BCP 47 tags, `.rules-for-ai`
   path fixes, `LOCALE.md` gitignore entry) as an independent commit before
   plugin work starts.
2. Rewrite the Language section of `AGENTS.md` to the three-layer chain:
   use a resolved locale keys when one is already in context (plugin path);
   otherwise read project `LOCALE.md`, then
   `~/.config/rules-for-ai/LOCALE.md`, then `LOCALE.default.md`.
3. Update the locale section of `hashiiiii-issues` to the same chain.
4. Rewrite the README around: install per tool, receiving updates, forking,
   and the submodule alternative.
5. Drop the project-level LOCALE layer (2026-07-05 revision): remove
   `$CLAUDE_PROJECT_DIR/LOCALE.md` from the hook resolution and the skills,
   delete `LOCALE.md.example`, drop the `LOCALE.md` entry from `.gitignore`,
   add the "project instructions override locale keys" precedence line to
   the Language section of `AGENTS.md` / `rules/agents.md`, rewrite the
   README locale and submodule sections, and invert the project-layer shell
   test into an ignored-file regression guard.

## Risks and open questions

- Verified 2026-07-05: Codex plugins can inject always-on context at session
  start. A plugin registers a `SessionStart` hook (via the `hooks` field in
  `.codex-plugin/plugin.json`, or a bundled `hooks/hooks.json`) matched on
  `source` values `startup`, `resume`, `clear`, `compact`; the hook's stdout,
  or `hookSpecificOutput.additionalContext` in its JSON output, is added as
  developer-visible context — mechanically equivalent to Claude Code's
  SessionStart hook. Caveat: plugin-bundled hooks are "non-managed" and must
  be reviewed and trusted once per hook hash via `/hooks` before Codex runs
  them; a changed hook needs re-trust. Implementing this hook is a follow-up
  issue, out of this plan's scope — the README's manual append to
  `~/.codex/AGENTS.md` remains the confirmed path meanwhile. Sources:
  https://developers.openai.com/codex/hooks and
  https://developers.openai.com/codex/plugins/build.
- Manifest schemas for Codex (`.codex-plugin/plugin.json`) and Cursor
  (`.cursor-plugin/plugin.json`) must be confirmed against current docs at
  implementation time; both are young formats and may have shifted.
- Onboarding UX exists only on Claude Code; Codex/Cursor users must discover
  `hashiiiii-locale` through the README.
- The Cursor import path targets team marketplaces; whether individual
  (non-team) users can import a GitHub plugin repo directly needs
  confirmation at implementation time. Fallbacks: manual placement under
  `~/.cursor/plugins/local/` or a later public marketplace listing.
