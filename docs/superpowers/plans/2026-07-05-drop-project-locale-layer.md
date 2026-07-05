# Drop Project-Level LOCALE Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the project-root `LOCALE.md` layer everywhere; project language policy moves to the consuming project's own `CLAUDE.md` / `AGENTS.md` as natural-language instructions that override the resolved locale keys.

**Architecture:** Locale resolution shrinks from three layers to two (user-level `~/.config/rules-for-ai/LOCALE.md`, then bundled `LOCALE.default.md`; first existing file wins as a whole). The injected rules gain one precedence line ("project instructions override locale keys"). A shell test asserts a project-root `LOCALE.md` is ignored, so the removed layer cannot silently return.

**Tech Stack:** POSIX sh (hook + tests, no mocks — real temp directories), Markdown (skills, rules, README), shellcheck, GitHub Actions CI.

**Spec:** `docs/superpowers/specs/2026-07-05-plugin-distribution-design.md` — see the "Revised: 2026-07-05" note, the Decisions table row "Project-level overrides", the paragraph "There is deliberately no project-level LOCALE layer", and Migration step 5.

## Global Constraints

- All docs, comments, and test log messages are English (repo-wide policy; Japanese reaches users only through downstream locale settings).
- Commits are exactly one line: `<type>: <subject>`, English, imperative, lowercase first word, no trailing period, subject ≤ 50 characters (types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert).
- No mocks or stubs — tests run the real hook against real files in temp directories.
- Prioritize comments in tests.
- `AGENTS.md` and `rules/agents.md` must stay byte-for-byte identical (CI runs `diff` on them).
- `CLAUDE.md` at the repo root is a symlink to `AGENTS.md` — never edit it separately.
- **Never stage these files** in any task: `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json` (uncommitted 2.0.0 version bump — releasing is done via `scripts/release.sh`, not by hand) and `.github/workflows/ci.yml` (unrelated checkout@v7 bump). They stay uncommitted when this plan finishes.
- Stage files explicitly by path in every commit step; never `git add -A` or `git add .`.

---

### Task 0: Commit the pending key=value locale refactor

The working tree already carries an uncommitted, coherent refactor (locale files switched from markdown tables to strict `key=value` lines; whole-file resolution). It touches the same files as this plan, so it must land first as its own commit — otherwise later commits would silently mix two concerns.

**Files:**
- Commit as-is (no edits in this task):
  - `hooks/session-start.sh`
  - `LOCALE.default.md`
  - `LOCALE.md.example`
  - `AGENTS.md`
  - `rules/agents.md`
  - `README.md`
  - `skills/hashiiiii-issues/SKILL.md`
  - `skills/hashiiiii-locale/SKILL.md`
  - `tests/session-start.test.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: a clean baseline — after this task, `git status` shows only the three plugin manifests and `.github/workflows/ci.yml` as modified. Every later task diffs against this baseline.

- [ ] **Step 1: Verify the pending work is green before committing it**

Run: `sh tests/session-start.test.sh`
Expected: every line starts with `PASS:`, final line `all tests passed`, exit 0.

Run: `shellcheck hooks/session-start.sh tests/session-start.test.sh`
Expected: no output, exit 0.

Run: `diff AGENTS.md rules/agents.md`
Expected: no output, exit 0.

- [ ] **Step 2: Commit the refactor (explicit paths only)**

```bash
git add hooks/session-start.sh LOCALE.default.md LOCALE.md.example AGENTS.md rules/agents.md README.md skills/hashiiiii-issues/SKILL.md skills/hashiiiii-locale/SKILL.md tests/session-start.test.sh
git commit -m "refactor: switch locale files to key=value format"
```

- [ ] **Step 3: Verify the remaining working-tree state**

Run: `git status --short`
Expected: exactly four modified entries — `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `.github/workflows/ci.yml`. Nothing else.

---

### Task 1: Hook ignores a project-root LOCALE.md (TDD)

**Files:**
- Modify: `hooks/session-start.sh`
- Test: `tests/session-start.test.sh` (header comment lines 8–10 and case 3, lines 77–94)

**Interfaces:**
- Consumes: the committed baseline from Task 0.
- Produces: `hooks/session-start.sh` that resolves exactly two layers (`$USER_CONFIG`, then `$PLUGIN_ROOT/LOCALE.default.md`) and never reads `$CLAUDE_PROJECT_DIR`. Tasks 2–5 describe this behavior in prose; they rely on this task, not the other way round.

- [ ] **Step 1: Rewrite test case 3 as the ignored-project-file regression guard**

In `tests/session-start.test.sh`, replace the header comment sentence (lines 8–10):

```sh
# LOCALE files are machine-written by the hashiiiii-locale skill, so the
# fixtures are complete (all four keys) except where a case exercises the
# first-file-wins rule itself.
```

with:

```sh
# LOCALE files are machine-written by the hashiiiii-locale skill, so the
# fixtures are complete (all four keys).
```

Replace all of case 3 (the block from `# Case 3:` through its `rm -rf "$root"`):

```sh
# Case 3: a project-root LOCALE.md is ignored. The project layer was
# removed on purpose: project language policy lives in the project's own
# CLAUDE.md / AGENTS.md, not in a LOCALE file. This case is the
# regression guard for that decision — the user file must win even when
# a project file exists.
root=$(new_fixture)
mkdir -p "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=ja_JP
comments=ja_JP
logs=ja_JP
test-logs=ja_JP
EOF
cat > "$root/project/LOCALE.md" <<'EOF'
issues=en_GB
comments=en_GB
logs=en_GB
test-logs=en_GB
EOF
out=$(run_hook "$root")
assert_contains "$out" 'issues=ja_JP' 'case 3: user file wins despite project file'
assert_not_contains "$out" 'en_GB' 'case 3: project file is ignored'
rm -rf "$root"
```

Leave `run_hook` itself untouched: it keeps setting `CLAUDE_PROJECT_DIR`, which is exactly what proves the hook ignores it.

- [ ] **Step 2: Run the tests to verify the new case fails**

Run: `sh tests/session-start.test.sh`
Expected: FAIL on both case 3 assertions —
`FAIL: case 3: user file wins despite project file (missing: issues=ja_JP)` and
`FAIL: case 3: project file is ignored (unexpected: en_GB)`,
final line `2 test(s) failed`, exit 1. All other cases PASS.

- [ ] **Step 3: Remove the project layer from the hook**

Replace the entire content of `hooks/session-start.sh` with:

```sh
#!/bin/sh
# SessionStart hook for the rules-for-ai plugin.
#
# Injects the always-on rules (AGENTS.md) and the locale keys into the
# session context. The first existing LOCALE file wins as a whole:
#   1. $XDG_CONFIG_HOME/rules-for-ai/LOCALE.md  (user; ~/.config fallback)
#   2. $CLAUDE_PLUGIN_ROOT/LOCALE.default.md    (bundled)
#
# There is deliberately no project-level layer: a project-root LOCALE.md
# is ignored. Project language policy lives in the project's own
# CLAUDE.md / AGENTS.md and overrides these keys.
#
# LOCALE files are machine-written by the hashiiiii-locale skill: strict
# key=value lines, always all four keys (issues, comments, logs,
# test-logs), LF endings. The hook trusts that format; layers never merge.
# This script must never break session start: it always exits 0.

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
USER_CONFIG="${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md"

# Always-on rules from the single source of truth.
if [ -f "$PLUGIN_ROOT/AGENTS.md" ]; then
    cat "$PLUGIN_ROOT/AGENTS.md"
else
    printf 'Warning: AGENTS.md not found in plugin; always-on rules were not injected.\n'
fi

locale_file=''
for f in "$USER_CONFIG" "$PLUGIN_ROOT/LOCALE.default.md"; do
    if [ -f "$f" ]; then
        locale_file=$f
        break
    fi
done

if [ -n "$locale_file" ]; then
    printf '\n## Locale (resolved)\n\n'
    grep -E '^(issues|comments|logs|test-logs)=' "$locale_file"
fi

# Onboarding: the existence of the user-level file means "configured".
if [ ! -f "$USER_CONFIG" ]; then
    printf '\nNo user-level locale preference is set. At the start of this session, ask the user which language to use for each artifact (Issues, Code comments, Log messages, Test log messages) and save the answer with the hashiiiii-locale skill. If the user is happy with the defaults, save the default file unchanged so this prompt never appears again.\n'
fi

exit 0
```

Note: the old `PROJECT_DIR=` line is gone entirely — an unused variable would trip shellcheck SC2034.

- [ ] **Step 4: Run the tests and shellcheck to verify green**

Run: `sh tests/session-start.test.sh`
Expected: all `PASS:`, final line `all tests passed`, exit 0.

Run: `shellcheck hooks/session-start.sh tests/session-start.test.sh`
Expected: no output, exit 0.

- [ ] **Step 5: Commit**

```bash
git add hooks/session-start.sh tests/session-start.test.sh
git commit -m "feat: drop project locale layer from hook"
```

---

### Task 2: Precedence line in the always-on rules

**Files:**
- Modify: `AGENTS.md` (Language section, lines 13–18)
- Modify: `rules/agents.md` (identical edit — CI enforces byte equality)

**Interfaces:**
- Consumes: Task 1's two-layer hook (the rules must describe what the hook actually does).
- Produces: the Language section wording that Task 3's skills and Task 5's README reference. The exact precedence sentence is "Project instructions (`CLAUDE.md` / `AGENTS.md`) override resolved locale keys".

- [ ] **Step 1: Rewrite the Language section in both files**

In `AGENTS.md`, replace:

```markdown
## Language

- If resolved locale keys are already in context (plugin path), follow them
- Otherwise read `LOCALE.md` at the project root
- If missing, read `~/.config/rules-for-ai/LOCALE.md`
- If missing, read `.rules-for-ai/LOCALE.default.md` (or `./LOCALE.default.md` when not using a submodule)
```

with:

```markdown
## Language

- Project instructions (`CLAUDE.md` / `AGENTS.md`) override resolved locale keys
- If resolved locale keys are already in context (plugin path), follow them
- Otherwise read `~/.config/rules-for-ai/LOCALE.md`
- If missing, read `.rules-for-ai/LOCALE.default.md` (or `./LOCALE.default.md` when not using a submodule)
```

Apply the exact same replacement in `rules/agents.md`. Do not touch `CLAUDE.md` — it is a symlink to `AGENTS.md`.

- [ ] **Step 2: Verify byte equality and that the hook tests still pass**

Run: `diff AGENTS.md rules/agents.md`
Expected: no output, exit 0.

Run: `sh tests/session-start.test.sh`
Expected: `all tests passed` (the fixtures copy `AGENTS.md`, so this proves the edit does not break injection).

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md rules/agents.md
git commit -m "feat: route project language policy via CLAUDE.md"
```

---

### Task 3: Scope the skills to the user-level file

**Files:**
- Modify: `skills/hashiiiii-locale/SKILL.md` (full rewrite below)
- Modify: `skills/hashiiiii-issues/SKILL.md` (resolution list, lines 12–18)

**Interfaces:**
- Consumes: Task 2's precedence sentence (repeated verbatim in the skills so a reader of either file sees the same rule).
- Produces: skill text with no project-level writes; nothing downstream consumes it programmatically.

- [ ] **Step 1: Replace the entire content of `skills/hashiiiii-locale/SKILL.md`**

```markdown
---
name: hashiiiii-locale
description: Use when setting or changing rules-for-ai locale preferences, or when onboarding says no user-level locale is set. Writes the user-level LOCALE.md.
---

# Locale Setup

Manage the user-level LOCALE file that rules-for-ai resolves at session start.

## Resolution order (first existing file wins)

1. `~/.config/rules-for-ai/LOCALE.md` (user level; respect `$XDG_CONFIG_HOME` when set)
2. Bundled `LOCALE.default.md` (all `en_US`)

The winning file is used as a whole; layers never merge. That is why every LOCALE file must carry all four keys.

There is no project-level LOCALE file. A project-specific language policy is an ordinary project instruction: it belongs in that project's `CLAUDE.md` / `AGENTS.md` (e.g. "Write issues in English"), and project instructions override resolved locale keys.

## When to Use

- When the session context says no user-level locale preference is set (onboarding)
- When the user asks to change the language of issues, code comments, or logs
- When the user wants a project-specific policy — do not write a LOCALE file; add the policy to that project's `CLAUDE.md` / `AGENTS.md` instead

## Arguments

- A single POSIX-style tag (`ja_JP`): apply it to all four keys
- Key=value pairs, one per artifact:

| Key | Artifact |
|-----|----------|
| `issues` | Issues |
| `comments` | Code comments |
| `logs` | Log messages |
| `test-logs` | Test log messages |

Example: `issues=ja_JP comments=ja_JP logs=en_US test-logs=en_US`

- No arguments: ask the user about each of the four artifacts individually — locales may differ per artifact.

## Writing the file

Always target `~/.config/rules-for-ai/LOCALE.md` (`$XDG_CONFIG_HOME/rules-for-ai/LOCALE.md` when `XDG_CONFIG_HOME` is set). Never write a LOCALE file into a project.

1. Validate keys: only the four keys above exist; reject anything else
2. Use POSIX-style tags (`ja_JP`, `en_US`, `en_GB`) as given; do not translate or normalize
3. Write strict `key=value` lines: no spaces around `=`, one key per line, LF line endings
4. Create the target directory when missing
5. Write atomically: write a temp file in the same directory, then `mv` it over the target
6. Always write all four keys; fill unspecified keys from the currently resolved values

File format (exactly this shape):

    # Locale

    issues=ja_JP
    comments=ja_JP
    logs=en_US
    test-logs=en_US

## When the user accepts the defaults

Write the default file (all `en_US`) to the user-level path unchanged. The existence of the file records the decision, so onboarding never fires again.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Writing a project-root `LOCALE.md` | The project layer does not exist; put project policy in that project's `CLAUDE.md` / `AGENTS.md` |
| Leaving keys out | Always write all four keys |
| Inventing keys like `commits` | Only the four keys in the table exist |
| Spaces around `=` (`issues = ja_JP`) | Strict `issues=ja_JP` only |
```

- [ ] **Step 2: Update the resolution list in `skills/hashiiiii-issues/SKILL.md`**

Replace:

```markdown
Before drafting an issue:

1. Use the resolved locale keys if they are already in context (plugin path)
2. Otherwise read `./LOCALE.md` at the project root
3. If missing, read `~/.config/rules-for-ai/LOCALE.md`
4. If missing, read the bundled `LOCALE.default.md`
5. Write the issue **title and body** in the language given by the `issues` key
```

with:

```markdown
Before drafting an issue:

1. Project instructions (`CLAUDE.md` / `AGENTS.md`) override resolved locale keys; follow them when they state a language for issues
2. Otherwise use the resolved locale keys if they are already in context (plugin path)
3. Otherwise read `~/.config/rules-for-ai/LOCALE.md`
4. If missing, read the bundled `LOCALE.default.md`
5. Write the issue **title and body** in the language given by the `issues` key
```

- [ ] **Step 3: Verify no project-layer references remain in the skills**

Run: `grep -rn "project root\|project-root\|project-level" skills/`
Expected: matches only in sentences that say the layer does not exist or redirect to `CLAUDE.md` / `AGENTS.md` (the two paragraphs and table row written above). No resolution step may mention a project `LOCALE.md`.

- [ ] **Step 4: Commit**

```bash
git add skills/hashiiiii-locale/SKILL.md skills/hashiiiii-issues/SKILL.md
git commit -m "feat: scope locale skills to user-level file"
```

---

### Task 4: Remove the project locale artifacts

**Files:**
- Delete: `LOCALE.md.example`
- Modify: `LOCALE.default.md` (prose only; the four keys stay)
- Modify: `.gitignore`

**Interfaces:**
- Consumes: nothing from other tasks (pure removal).
- Produces: repo without `LOCALE.md.example`; Task 5's README must not reference that file.

- [ ] **Step 1: Delete the sample file**

```bash
git rm LOCALE.md.example
```

- [ ] **Step 2: Rewrite `LOCALE.default.md` prose (it still points at the project root)**

Replace the entire content of `LOCALE.default.md` with:

```markdown
# Locale

Fallback language settings. Agents read this file only when no user-level `LOCALE.md` exists — the first existing file wins as a whole; layers never merge.

To override, run the hashiiiii-locale skill or create `~/.config/rules-for-ai/LOCALE.md` manually, keeping all four keys.

POSIX-style locale tags (e.g. `ja_JP`, `en_US`, `en_GB`).

issues=en_US
comments=en_US
logs=en_US
test-logs=en_US
```

- [ ] **Step 3: Drop the `LOCALE.md` entry from `.gitignore`**

Replace the entire content of `.gitignore` with:

```
.vscode/
.superpowers/
```

- [ ] **Step 4: Verify the hook still resolves the rewritten default**

Run: `sh tests/session-start.test.sh`
Expected: `all tests passed` (case 1 asserts `issues=en_US` from the bundled default, which proves the rewritten file still parses).

Run: `grep -rn "LOCALE.md.example" . --include="*.md" --include="*.sh" --exclude-dir=.git --exclude-dir=docs`
Expected: exactly one match — `README.md` (removed in Task 5). `docs/` is excluded because the spec's migration history legitimately names the file.

- [ ] **Step 5: Commit**

```bash
git add LOCALE.md.example LOCALE.default.md .gitignore
git commit -m "chore: remove project-level locale remnants"
```

---

### Task 5: README — two-layer chain and submodule section

**Files:**
- Modify: `README.md` (contents table line 11; install line 43; Locale section lines 67–81; submodule section lines 97–103 and 119)

**Interfaces:**
- Consumes: Task 4 (the `LOCALE.md.example` row must go because the file is gone), Task 2's precedence sentence.
- Produces: user-facing docs; nothing downstream.

- [ ] **Step 1: Remove the sample row from the contents table**

Delete this line from the table (line 11):

```markdown
| `LOCALE.md.example` | Sample for project-root `LOCALE.md` |
```

- [ ] **Step 2: Fix the install section wording (line 43)**

Replace:

```markdown
Once installed, a SessionStart hook injects `AGENTS.md` plus the resolved locale table into every session automatically — no extra step.
```

with:

```markdown
Once installed, a SessionStart hook injects `AGENTS.md` plus the resolved locale keys into every session automatically — no extra step.
```

- [ ] **Step 3: Rewrite the Locale section**

Replace the whole `## Locale` section (from the heading through the line "No per-project `LOCALE.md` is needed unless you want to override the user-level (or default) setting for that project.") with:

```markdown
## Locale

Language settings resolve as one file — the first existing layer wins as a whole:

1. `~/.config/rules-for-ai/LOCALE.md` (user level; respects `$XDG_CONFIG_HOME`)
2. Bundled `LOCALE.default.md` (fallback, all `en_US`)

Four artifacts are configurable independently: Issues, Code comments, Log messages, Test log messages. Each layer is a `LOCALE.md` file of `key=value` lines (`issues`, `comments`, `logs`, `test-logs`).

There is no project-level `LOCALE.md`. A project-specific language policy is an ordinary project instruction: write it in that project's `CLAUDE.md` / `AGENTS.md` (e.g. "Write issues in English") and it overrides the resolved keys — readable by every collaborator, no `.gitignore` entry needed.

On Claude Code, the SessionStart hook resolves and injects these keys every session. If no user-level file exists yet, onboarding fires once: the agent asks which language to use for each artifact and saves the answer with the `hashiiiii-locale` skill (accepting the defaults still records the choice, so the prompt does not repeat).

On Codex and Cursor, there is no hook, so resolution is model-driven: run the `hashiiiii-locale` skill, or create `~/.config/rules-for-ai/LOCALE.md` manually, following the same two-layer order.
```

- [ ] **Step 4: Update the submodule section**

In the setup code block (lines 97–103), delete the line:

```bash
cp .rules-for-ai/LOCALE.md.example LOCALE.md   # optional; skip to use defaults
```

Replace the language paragraph (line 119):

```markdown
Language settings (issues, code comments, logs) live in `LOCALE.md` at the project root as `key=value` lines (see `LOCALE.md.example`). Without one, agents fall back through the user-level file and then `LOCALE.default.md`, which defaults everything to English. Commit `LOCALE.md` at the project root — it lives outside the submodule, so `git submodule update` never touches it.
```

with:

```markdown
Language settings resolve the same two-layer chain as the plugin path: `~/.config/rules-for-ai/LOCALE.md`, then the bundled `LOCALE.default.md` (all English). For a project-specific language policy, add plain instructions to the project's `CLAUDE.md` / `AGENTS.md` (with the symlink setup above, that means your fork's `AGENTS.md`).
```

- [ ] **Step 5: Verify no stale references remain**

Run: `grep -n "LOCALE.md.example\|project root\|Project \`LOCALE.md\`" README.md`
Expected: no matches for `LOCALE.md.example`; any remaining "project root" hits refer to `AGENTS.md` / `CLAUDE.md` symlinks, not to a LOCALE file.

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: update readme for two-layer locale chain"
```

---

### Task 6: Full verification pass (no commit)

**Files:**
- None modified. Read-only checks.

**Interfaces:**
- Consumes: everything above.
- Produces: evidence that the branch is green and the tree is in the expected state.

- [ ] **Step 1: Run everything CI runs**

```bash
shellcheck hooks/session-start.sh scripts/check-versions.sh scripts/release.sh tests/session-start.test.sh tests/release.test.sh
sh tests/session-start.test.sh
diff AGENTS.md rules/agents.md
sh scripts/check-versions.sh
```

Expected: shellcheck silent; `all tests passed`; diff silent; version check passes (all three manifests read 2.0.0 in the working tree — consistent with each other, which is all the lockstep check asserts).

- [ ] **Step 2: Sweep for resurrected project-layer references**

```bash
grep -rn "PROJECT_DIR\|project/LOCALE\|LOCALE.md.example" hooks/ skills/ tests/ AGENTS.md rules/ README.md .gitignore
```

Expected: matches only in `tests/session-start.test.sh` (the decoy `$root/project/LOCALE.md` fixture in case 3 and the `CLAUDE_PROJECT_DIR` env line in `run_hook` — both exist precisely to prove the hook ignores them). Zero matches anywhere else.

- [ ] **Step 3: Confirm the intentionally uncommitted files are untouched**

Run: `git status --short`
Expected: exactly the three plugin manifests and `.github/workflows/ci.yml` as modified (out of scope: manifest bump belongs to `scripts/release.sh`; the checkout@v7 bump is a separate chore for the user to commit or discard).
