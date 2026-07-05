# Plugin Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package this repository as an installable plugin for Claude Code, Codex, and Cursor, with hook-injected always-on rules, three-layer locale resolution, and lockstep semver releases.

**Architecture:** Single repo, three thin manifests over one content tree. A Claude Code SessionStart hook injects `AGENTS.md` plus a resolved locale table; Cursor consumes an exact copy under `rules/`; Codex gets a documented manual step until plugin injection is verified. Spec: `docs/superpowers/specs/2026-07-05-plugin-distribution-design.md`.

**Tech Stack:** POSIX sh + awk (hook, scripts, tests — no bats, no mocks), JSON manifests, Agent Skills markdown, GitHub Actions.

## Global Constraints

- All docs, comments, and test log messages in English (repo is English-only)
- No emojis; half-width space between full-width and half-width characters
- No mocks or stubs — tests use real files, real temp dirs, real git repos
- Prioritize comments in tests
- Shell scripts are POSIX sh and must pass shellcheck
- Commits per `hashiiiii-git`: `<type>: <subject>`, one line, English, imperative, ≤ 50 chars
- Initial plugin version: `0.1.0`; the three manifests always carry identical versions
- Work happens on branch `feat/plugin-distribution` (created in Task 1 from `docs/plugin-distribution-design`, which already holds the spec commit)

---

### Task 1: Land pending working-tree refinements

The tree has uncommitted refinements (BCP 47 tags, `.rules-for-ai` path fixes, `LOCALE.md` gitignore entry) that the spec's migration step 1 requires landing before plugin work.

**Files:**
- Modify (already modified, commit as-is): `.gitignore`, `AGENTS.md`, `LOCALE.default.md`, `LOCALE.md.example`, `README.md`, `skills/hashiiiii-issues/SKILL.md`

**Interfaces:**
- Produces: a clean working tree; `LOCALE.default.md` rows use BCP 47 tags (`en_US`) that Task 4's tests assert on

- [ ] **Step 1: Create the working branch**

```bash
git switch docs/plugin-distribution-design
git switch -c feat/plugin-distribution
```

- [ ] **Step 2: Verify the diff is only the six expected files**

Run: `git status --short`
Expected: exactly the six files above, all ` M`.

- [ ] **Step 3: Commit**

```bash
git add .gitignore AGENTS.md LOCALE.default.md LOCALE.md.example README.md skills/hashiiiii-issues/SKILL.md
git commit -m "fix: use bcp 47 tags and hidden submodule path"
```

### Task 2: Verify Codex plugin injection mechanism

Research task (spec risk #1). Determines whether Codex always-on rules ship in the plugin or as a README manual step.

**Files:**
- Modify: `docs/superpowers/specs/2026-07-05-plugin-distribution-design.md` (Risks section — record the verified answer)

**Interfaces:**
- Produces: a verified yes/no on "can a Codex plugin inject always-on context at session start", consumed by Task 10 (README Codex section)

- [ ] **Step 1: Check current Codex plugin docs**

Fetch and read:
- `https://developers.openai.com/codex/plugins`
- `https://developers.openai.com/codex/plugins/build`
- `https://developers.openai.com/codex/skills`

Look for: hook events fired at session/conversation start whose output is added to context, or any manifest field that injects instructions.

- [ ] **Step 2: Record the outcome in the spec's Risks section**

Replace the "Codex plugin hooks are unverified" bullet with the finding, dated. If injection IS possible: note the mechanism; implementing it becomes a follow-up issue (out of this plan's scope — the README manual step still works meanwhile). If NOT possible: state that the README manual step is the confirmed path.

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-07-05-plugin-distribution-design.md
git commit -m "docs: record codex injection verification"
```

### Task 3: Rewrite AGENTS.md language section and add Cursor rules copy

**Files:**
- Modify: `AGENTS.md` (Language section only)
- Create: `rules/agents.md` (exact copy)

**Interfaces:**
- Produces: `AGENTS.md` whose Language section matches the three-layer chain; `rules/agents.md` byte-identical to `AGENTS.md` (Task 8's CI diff and Task 4's hook both consume `AGENTS.md`)

- [ ] **Step 1: Replace the Language section of `AGENTS.md`**

Current:

```markdown
## Language

- Read `LOCALE.md` at the project root for language settings
- If `LOCALE.md` is missing, read `.rules-for-ai/LOCALE.default.md` (or `./LOCALE.default.md` when not using a submodule)
```

New:

```markdown
## Language

- If a resolved locale table is already in context (plugin path), follow it
- Otherwise read `LOCALE.md` at the project root
- If missing, read `~/.config/rules-for-ai/LOCALE.md`
- If missing, read `.rules-for-ai/LOCALE.default.md` (or `./LOCALE.default.md` when not using a submodule)
```

- [ ] **Step 2: Create the Cursor copy**

```bash
mkdir -p rules
cp AGENTS.md rules/agents.md
```

- [ ] **Step 3: Verify zero drift**

Run: `diff AGENTS.md rules/agents.md`
Expected: no output, exit 0.

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md rules/agents.md
git commit -m "feat: add always-on rules copy for cursor"
```

### Task 4: SessionStart hook with locale resolution (TDD)

**Files:**
- Create: `hooks/session-start.sh`, `hooks/hooks.json`
- Test: `tests/session-start.test.sh`

**Interfaces:**
- Consumes: `AGENTS.md`, `LOCALE.default.md` (BCP 47 rows from Task 1)
- Produces: `hooks/session-start.sh` — env contract: reads `CLAUDE_PLUGIN_ROOT`, `CLAUDE_PROJECT_DIR`, `XDG_CONFIG_HOME` (fallback `$HOME/.config`); prints injected context to stdout; always exits 0. `hooks/hooks.json` registers it. Onboarding text references the `hashiiiii-locale` skill (Task 5).

- [ ] **Step 1: Write the failing test**

Create `tests/session-start.test.sh` (mode 755):

```sh
#!/bin/sh
# Tests for hooks/session-start.sh.
#
# Each case builds a real directory layout under a temp root and runs the
# hook with CLAUDE_PLUGIN_ROOT / CLAUDE_PROJECT_DIR / XDG_CONFIG_HOME
# pointing into it. No mocks or stubs; the hook reads real files.
set -u

REPO="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
HOOK="$REPO/hooks/session-start.sh"
failures=0

# assert_contains <haystack> <needle> <case description>
assert_contains() {
    case "$1" in
        *"$2"*) printf 'PASS: %s\n' "$3" ;;
        *) printf 'FAIL: %s (missing: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
    esac
}

# assert_not_contains <haystack> <needle> <case description>
assert_not_contains() {
    case "$1" in
        *"$2"*) printf 'FAIL: %s (unexpected: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
        *) printf 'PASS: %s\n' "$3" ;;
    esac
}

# new_fixture: fresh temp root holding a plugin dir (AGENTS.md and
# LOCALE.default.md copied from the repo), an empty project dir, and an
# empty config home. Prints the root path.
new_fixture() {
    fixture_root=$(mktemp -d)
    mkdir -p "$fixture_root/plugin" "$fixture_root/project" "$fixture_root/config"
    cp "$REPO/AGENTS.md" "$fixture_root/plugin/AGENTS.md"
    cp "$REPO/LOCALE.default.md" "$fixture_root/plugin/LOCALE.default.md"
    printf '%s' "$fixture_root"
}

# run_hook <fixture root>: run the hook against the fixture's layout.
run_hook() {
    CLAUDE_PLUGIN_ROOT="$1/plugin" \
    CLAUDE_PROJECT_DIR="$1/project" \
    XDG_CONFIG_HOME="$1/config" \
    HOME="$1" \
    sh "$HOOK"
}

# Case 1: nothing configured -> defaults everywhere plus onboarding.
root=$(new_fixture)
out=$(run_hook "$root")
assert_contains "$out" '# AGENTS' 'case 1: always-on rules injected'
assert_contains "$out" '| Issues | en_US |' 'case 1: Issues falls back to default'
assert_contains "$out" 'hashiiiii-locale' 'case 1: onboarding instruction present'
rm -rf "$root"

# Case 2: user config only -> user rows win, missing rows fall back,
# and onboarding stays quiet.
root=$(new_fixture)
mkdir -p "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
| Artifact | Language |
|----------|----------|
| Issues | ja_JP |
EOF
out=$(run_hook "$root")
assert_contains "$out" '| Issues | ja_JP |' 'case 2: user row overrides default'
assert_contains "$out" '| Code comments | en_US |' 'case 2: missing rows fall back'
assert_not_contains "$out" 'No user-level locale preference' 'case 2: no onboarding when configured'
rm -rf "$root"

# Case 3: project row beats user row; untouched rows keep user values.
root=$(new_fixture)
mkdir -p "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
| Artifact | Language |
|----------|----------|
| Issues | ja_JP |
| Code comments | ja_JP |
EOF
cat > "$root/project/LOCALE.md" <<'EOF'
| Artifact | Language |
|----------|----------|
| Issues | en_GB |
EOF
out=$(run_hook "$root")
assert_contains "$out" '| Issues | en_GB |' 'case 3: project row wins over user row'
assert_contains "$out" '| Code comments | ja_JP |' 'case 3: user row survives for other artifacts'
rm -rf "$root"

# Case 4: malformed user table -> warning, defaults, and the file still
# counts as "configured" so onboarding must not fire.
root=$(new_fixture)
mkdir -p "$root/config/rules-for-ai"
printf 'this is not a table\n' > "$root/config/rules-for-ai/LOCALE.md"
out=$(run_hook "$root")
assert_contains "$out" 'Warning: user LOCALE.md exists but has no recognizable locale rows' 'case 4: warning emitted'
assert_contains "$out" '| Issues | en_US |' 'case 4: falls back to defaults'
assert_not_contains "$out" 'No user-level locale preference' 'case 4: existing file counts as configured'
rm -rf "$root"

# Case 5: the hook must exit 0 even when every input is missing.
root=$(mktemp -d)
CLAUDE_PLUGIN_ROOT="$root/nope" CLAUDE_PROJECT_DIR="$root/nope" \
XDG_CONFIG_HOME="$root/nope" HOME="$root" sh "$HOOK" > /dev/null 2>&1
status=$?
if [ "$status" -eq 0 ]; then
    printf 'PASS: case 5: exit 0 with nothing available\n'
else
    printf 'FAIL: case 5: exit status %s\n' "$status"
    failures=$((failures + 1))
fi
rm -rf "$root"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `sh tests/session-start.test.sh`
Expected: FAIL lines (hook does not exist yet; case 5 fails with a non-zero `sh` status).

- [ ] **Step 3: Implement the hook**

Create `hooks/session-start.sh` (mode 755):

```sh
#!/bin/sh
# SessionStart hook for the rules-for-ai plugin.
#
# Injects the always-on rules (AGENTS.md) and the resolved locale table
# into the session context. Locale resolution is per row; the first layer
# with a value for an artifact wins:
#   1. $CLAUDE_PROJECT_DIR/LOCALE.md            (project)
#   2. $XDG_CONFIG_HOME/rules-for-ai/LOCALE.md  (user; ~/.config fallback)
#   3. $CLAUDE_PLUGIN_ROOT/LOCALE.default.md    (bundled)
#
# This script must never break session start: it always exits 0.

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/rules-for-ai/LOCALE.md"

PROJECT_LOCALE="$PROJECT_DIR/LOCALE.md"
DEFAULT_LOCALE="$PLUGIN_ROOT/LOCALE.default.md"

# Print "artifact<TAB>language" for every recognized row in a locale
# table. Unknown rows, the header row, and the separator row are ignored.
parse_locale_file() {
    [ -f "$1" ] || return 0
    awk -F'|' '
        NF >= 3 {
            key = $2; val = $3
            gsub(/^[ \t]+/, "", key); gsub(/[ \t]+$/, "", key)
            gsub(/^[ \t]+/, "", val); gsub(/[ \t]+$/, "", val)
            if (key != "Issues" && key != "Code comments" && \
                key != "Log messages" && key != "Test log messages") next
            if (val == "" || val == "Language") next
            if (val ~ /^-+$/) next
            print key "\t" val
        }
    ' "$1" 2>/dev/null
}

# Resolve one artifact across the three layers; en_US as the last resort.
resolve_row() {
    artifact="$1"
    for f in "$PROJECT_LOCALE" "$USER_CONFIG" "$DEFAULT_LOCALE"; do
        v=$(parse_locale_file "$f" | awk -F'\t' -v a="$artifact" '$1 == a { print $2; exit }')
        if [ -n "$v" ]; then
            printf '%s' "$v"
            return 0
        fi
    done
    printf 'en_US'
}

# A present-but-unparseable layer is dropped with a warning.
warn_if_unparseable() {
    if [ -f "$1" ] && [ -z "$(parse_locale_file "$1")" ]; then
        printf '\nWarning: %s exists but has no recognizable locale rows; it was ignored.\n' "$2"
    fi
}

# Always-on rules from the single source of truth.
if [ -f "$PLUGIN_ROOT/AGENTS.md" ]; then
    cat "$PLUGIN_ROOT/AGENTS.md"
else
    printf 'Warning: AGENTS.md not found in plugin; always-on rules were not injected.\n'
fi

printf '\n## Locale (resolved)\n\n'
printf '| Artifact | Language |\n'
printf '|----------|----------|\n'
for artifact in 'Issues' 'Code comments' 'Log messages' 'Test log messages'; do
    printf '| %s | %s |\n' "$artifact" "$(resolve_row "$artifact")"
done

warn_if_unparseable "$PROJECT_LOCALE" "project LOCALE.md"
warn_if_unparseable "$USER_CONFIG" "user LOCALE.md"

# Onboarding: the existence of the user-level file means "configured".
if [ ! -f "$USER_CONFIG" ]; then
    printf '\nNo user-level locale preference is set. At the start of this session, ask the user which language to use for each artifact (Issues, Code comments, Log messages, Test log messages) and save the answer with the hashiiiii-locale skill. If the user is happy with the defaults, save the default table unchanged so this prompt never appears again.\n'
fi

exit 0
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `sh tests/session-start.test.sh`
Expected: all PASS lines, final line `all tests passed`, exit 0.

- [ ] **Step 5: Run shellcheck**

Run: `shellcheck hooks/session-start.sh tests/session-start.test.sh`
Expected: no output. (Install via `brew install shellcheck` if missing.)

- [ ] **Step 6: Register the hook**

Create `hooks/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

No matcher means it fires on every SessionStart source (startup, resume, clear, compact). Real firing is verified in Task 11.

- [ ] **Step 7: Commit**

```bash
git add hooks/session-start.sh hooks/hooks.json tests/session-start.test.sh
git commit -m "feat: add session-start hook with locale table"
```

### Task 5: hashiiiii-locale skill

**Files:**
- Create: `skills/hashiiiii-locale/SKILL.md`

**Interfaces:**
- Consumes: the onboarding instruction text from Task 4 (references this skill by name)
- Produces: the skill that writes `~/.config/rules-for-ai/LOCALE.md` or a project-root `LOCALE.md`

- [ ] **Step 1: Create the skill**

Create `skills/hashiiiii-locale/SKILL.md`:

```markdown
---
name: hashiiiii-locale
description: Use when setting or changing rules-for-ai locale preferences, or when onboarding says no user-level locale is set. Writes the user-level or project-level LOCALE.md.
---

# Locale Setup

Manage the LOCALE tables that rules-for-ai resolves at session start.

## Resolution order (per row, first hit wins)

1. `LOCALE.md` at the project root
2. `~/.config/rules-for-ai/LOCALE.md` (user level; respect `$XDG_CONFIG_HOME` when set)
3. Bundled `LOCALE.default.md` (all `en_US`)

## When to Use

- When the session context says no user-level locale preference is set (onboarding)
- When the user asks to change the language of issues, code comments, or logs
- When the user wants a project-specific override

## Arguments

- A single BCP 47 tag (`ja_JP`): apply it to all four artifacts
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

Target `~/.config/rules-for-ai/LOCALE.md` by default (`$XDG_CONFIG_HOME/rules-for-ai/LOCALE.md` when `XDG_CONFIG_HOME` is set). Write a project-root `LOCALE.md` instead only when the user asks for a project-specific override.

1. Validate keys: only the four keys above exist; reject anything else
2. Use BCP 47 tags (`ja_JP`, `en_US`, `en_GB`) as given; do not translate or normalize
3. Create the target directory when missing
4. Write atomically: write a temp file in the same directory, then `mv` it over the target
5. Always write all four rows; fill unspecified rows from the currently resolved values

File format (exactly this shape):

    # Locale

    | Artifact | Language |
    |----------|----------|
    | Issues | ja_JP |
    | Code comments | ja_JP |
    | Log messages | en_US |
    | Test log messages | en_US |

## When the user accepts the defaults

Write the default table (all `en_US`) to the user-level path unchanged. The existence of the file records the decision, so onboarding never fires again.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Writing the project file during onboarding | Onboarding targets the user-level path |
| Leaving rows out | Always write all four rows |
| Inventing keys like `commits` | Only the four keys in the table exist |
```

- [ ] **Step 2: Verify frontmatter parses**

Run: `head -5 skills/hashiiiii-locale/SKILL.md`
Expected: `---`, `name: hashiiiii-locale`, a `description:` line, `---`.

- [ ] **Step 3: Commit**

```bash
git add skills/hashiiiii-locale/SKILL.md
git commit -m "feat: add hashiiiii-locale skill"
```

### Task 6: Plugin manifests for the three tools

**Files:**
- Create: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json`

**Interfaces:**
- Produces: three manifests each carrying `"version": "0.1.0"` (Task 7's check script parses the `"version"` field; Task 11 installs from `.claude-plugin/marketplace.json`)

- [ ] **Step 1: Check current manifest schemas**

Before writing, confirm field names against current docs (spec risk #2):
- Claude Code: `https://code.claude.com/docs/en/plugins` and `https://code.claude.com/docs/en/plugin-marketplaces`
- Codex: `https://developers.openai.com/codex/plugins/build`
- Cursor: `https://cursor.com/docs/reference/plugins`

Adjust the JSON below only where the docs contradict it; keep `name`, `version`, `description` present in all three regardless.

- [ ] **Step 2: Create the Claude Code manifest and marketplace**

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "rules-for-ai",
  "version": "0.1.0",
  "description": "Portable rules and skills for AI coding agents",
  "author": { "name": "hashiiiii" },
  "repository": "https://github.com/hashiiiii/rules-for-ai",
  "license": "MIT"
}
```

Create `.claude-plugin/marketplace.json`:

```json
{
  "name": "rules-for-ai",
  "owner": { "name": "hashiiiii" },
  "plugins": [
    {
      "name": "rules-for-ai",
      "source": "./",
      "description": "Portable rules and skills for AI coding agents"
    }
  ]
}
```

- [ ] **Step 3: Create the Codex and Cursor manifests**

Create `.codex-plugin/plugin.json`:

```json
{
  "name": "rules-for-ai",
  "version": "0.1.0",
  "description": "Portable rules and skills for AI coding agents"
}
```

Create `.cursor-plugin/plugin.json`:

```json
{
  "name": "rules-for-ai",
  "version": "0.1.0",
  "description": "Portable rules and skills for AI coding agents"
}
```

- [ ] **Step 4: Validate**

Run: `claude plugin validate .`
Expected: validation passes for the Claude Code manifest and marketplace.
Also run: `python3 -m json.tool < .codex-plugin/plugin.json && python3 -m json.tool < .cursor-plugin/plugin.json`
Expected: both print parsed JSON, exit 0.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin .codex-plugin .cursor-plugin
git commit -m "feat: add plugin manifests for three tools"
```

### Task 7: Version check and release scripts (TDD)

**Files:**
- Create: `scripts/check-versions.sh`, `scripts/release.sh`
- Test: `tests/release.test.sh`

**Interfaces:**
- Consumes: the three manifests from Task 6 (flat JSON objects with a `"version"` field)
- Produces: `scripts/check-versions.sh` — exits 0 and prints `versions in lockstep: X.Y.Z` when the three manifests match, exits 1 otherwise. `scripts/release.sh <new-version>` — bumps all three, commits `build: release vX.Y.Z`, tags `vX.Y.Z`, pushes. CI (Task 8) runs both test scripts and the check.

- [ ] **Step 1: Write the failing test**

Create `tests/release.test.sh` (mode 755):

```sh
#!/bin/sh
# Tests for scripts/release.sh and scripts/check-versions.sh.
#
# Builds a throwaway git repo containing the three manifests and a local
# bare remote, then performs a real release: commit, tag, and push are
# all exercised for real. No mocks or stubs.
set -eu

REPO="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

# Arrange: a work repo with all manifests at 0.0.1 and a bare origin.
git init -q "$root/work"
git init -q --bare "$root/origin.git"
cd "$root/work"
git remote add origin "$root/origin.git"
git config user.email test@example.com
git config user.name test
mkdir -p .claude-plugin .codex-plugin .cursor-plugin scripts
for m in .claude-plugin .codex-plugin .cursor-plugin; do
    printf '{\n  "name": "rules-for-ai",\n  "version": "0.0.1"\n}\n' > "$m/plugin.json"
done
cp "$REPO/scripts/release.sh" scripts/release.sh
cp "$REPO/scripts/check-versions.sh" scripts/check-versions.sh
git add -A
git commit -qm "chore: seed fixture repo"
git branch -q -M main
git push -qu origin main

# Sanity: the lockstep check passes on the seeded state.
scripts/check-versions.sh | grep -q '0.0.1' || { printf 'FAIL: seed check\n'; exit 1; }
printf 'PASS: check-versions accepts lockstep manifests\n'

# A deliberate mismatch must be rejected.
printf '{\n  "name": "rules-for-ai",\n  "version": "9.9.9"\n}\n' > .cursor-plugin/plugin.json
if scripts/check-versions.sh > /dev/null 2>&1; then
    printf 'FAIL: check-versions accepted a mismatch\n'
    exit 1
fi
printf 'PASS: check-versions rejects a mismatch\n'
git checkout -- .cursor-plugin/plugin.json

# Act: a real release.
scripts/release.sh 0.2.0

# Assert: manifests bumped in lockstep, tag present on the remote.
scripts/check-versions.sh | grep -q '0.2.0' || { printf 'FAIL: manifests not bumped\n'; exit 1; }
printf 'PASS: release bumps all manifests\n'
git ls-remote --tags origin | grep -q 'refs/tags/v0.2.0' || { printf 'FAIL: tag not pushed\n'; exit 1; }
printf 'PASS: release pushes the tag\n'

printf 'all release tests passed\n'
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `sh tests/release.test.sh`
Expected: FAIL (the `cp` of the not-yet-existing scripts aborts the run).

- [ ] **Step 3: Implement the check script**

Create `scripts/check-versions.sh` (mode 755):

```sh
#!/bin/sh
# Verify the three plugin manifests carry the same version (lockstep).
set -eu

# Minimal JSON "version" extraction; the manifests are flat objects we
# own, so a sed pull of the first "version" value is sufficient.
extract_version() {
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n 1
}

claude=$(extract_version .claude-plugin/plugin.json)
codex=$(extract_version .codex-plugin/plugin.json)
cursor=$(extract_version .cursor-plugin/plugin.json)

if [ -z "$claude" ] || [ "$claude" != "$codex" ] || [ "$claude" != "$cursor" ]; then
    printf 'version mismatch: claude=%s codex=%s cursor=%s\n' "$claude" "$codex" "$cursor" >&2
    exit 1
fi
printf 'versions in lockstep: %s\n' "$claude"
```

- [ ] **Step 4: Implement the release script**

Create `scripts/release.sh` (mode 755):

```sh
#!/bin/sh
# Bump the plugin version in all three manifests, commit, tag, and push.
# Usage: scripts/release.sh <new-version>   e.g. scripts/release.sh 0.2.0
set -eu

[ $# -eq 1 ] || { printf 'usage: scripts/release.sh <new-version>\n' >&2; exit 1; }
new="$1"
case "$new" in
    [0-9]*.[0-9]*.[0-9]*) ;;
    *) printf 'not a semver version: %s\n' "$new" >&2; exit 1 ;;
esac

for manifest in .claude-plugin/plugin.json .codex-plugin/plugin.json .cursor-plugin/plugin.json; do
    sed -i.bak "s/\"version\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"version\": \"$new\"/" "$manifest"
    rm -f "$manifest.bak"
done

scripts/check-versions.sh

git add .claude-plugin/plugin.json .codex-plugin/plugin.json .cursor-plugin/plugin.json
git commit -m "build: release v$new"
git tag "v$new"
git push origin HEAD "v$new"
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `sh tests/release.test.sh`
Expected: all PASS lines, final line `all release tests passed`, exit 0.

- [ ] **Step 6: Run shellcheck**

Run: `shellcheck scripts/check-versions.sh scripts/release.sh tests/release.test.sh`
Expected: no output.

- [ ] **Step 7: Commit**

```bash
git add scripts/check-versions.sh scripts/release.sh tests/release.test.sh
git commit -m "build: add release and version check scripts"
```

### Task 8: CI workflow

**Files:**
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: both test scripts, `scripts/check-versions.sh`, and the `AGENTS.md` / `rules/agents.md` pair

- [ ] **Step 1: Create the workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: shellcheck
        run: shellcheck hooks/session-start.sh scripts/check-versions.sh scripts/release.sh tests/session-start.test.sh tests/release.test.sh
      - name: hook tests
        run: sh tests/session-start.test.sh
      - name: release tests
        run: sh tests/release.test.sh
      - name: always-on rules drift check
        run: diff AGENTS.md rules/agents.md
      - name: manifest version lockstep
        run: scripts/check-versions.sh
```

- [ ] **Step 2: Run every CI step locally**

```bash
shellcheck hooks/session-start.sh scripts/check-versions.sh scripts/release.sh tests/session-start.test.sh tests/release.test.sh
sh tests/session-start.test.sh
sh tests/release.test.sh
diff AGENTS.md rules/agents.md
scripts/check-versions.sh
```

Expected: every command exits 0.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add tests and drift checks"
```

### Task 9: Update hashiiiii-issues locale chain

**Files:**
- Modify: `skills/hashiiiii-issues/SKILL.md` (Locale section only)

- [ ] **Step 1: Replace the Locale section steps**

Current steps 1-3 under `## Locale`:

```markdown
1. Read `./LOCALE.md` at the project root
2. If missing, read `.rules-for-ai/LOCALE.default.md` (or `./LOCALE.default.md` when not using a submodule)
3. Write the issue **title and body** in the language given by the `Issues` row
```

New:

```markdown
1. Use the resolved locale table if one is already in context (plugin path)
2. Otherwise read `./LOCALE.md` at the project root
3. If missing, read `~/.config/rules-for-ai/LOCALE.md`
4. If missing, read the bundled `LOCALE.default.md` (`.rules-for-ai/LOCALE.default.md` when using the submodule)
5. Write the issue **title and body** in the language given by the `Issues` row
```

- [ ] **Step 2: Commit**

```bash
git add skills/hashiiiii-issues/SKILL.md
git commit -m "fix: update issues skill locale chain"
```

### Task 10: README rewrite

**Files:**
- Modify: `README.md` (full rewrite of the "Use in a project" area; keep the Contents table and License)

- [ ] **Step 1: Rewrite the README**

Structure (all content English; each section must contain the verbatim snippets below):

1. `# Rules for AI` — keep the one-line intro.
2. `## Contents` — extend the existing table with rows for `skills/hashiiiii-locale/`, `hooks/`, `rules/`, and the three manifest directories.
3. `## Install as a plugin` with one subsection per tool:
   - **Claude Code**:

     ```
     /plugin marketplace add hashiiiii/rules-for-ai
     /plugin install rules-for-ai@rules-for-ai
     ```

     Include the team auto-enable snippet for a consuming repo's `.claude/settings.json`:

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

   - **Codex**: `codex plugin marketplace add hashiiiii/rules-for-ai`, install from `/plugins`. Add the always-on rules step per Task 2's verified outcome (manual `~/.codex/AGENTS.md` append, or the verified injection mechanism).
   - **Cursor**: import `https://github.com/hashiiiii/rules-for-ai` via a team marketplace; note the local-path fallback `~/.cursor/plugins/local/`.
4. `## Locale` — the three-layer resolution order, the four artifacts, onboarding behavior on Claude Code, and pointing Codex/Cursor users at `hashiiiii-locale`. State that no per-project file is needed unless overriding.
5. `## Receiving updates` — per tool: Claude Code startup check plus `/plugin marketplace update rules-for-ai` (auto-update off by default for third-party marketplaces); Codex `codex plugin marketplace upgrade`; Cursor auto-refresh of imported repos.
6. `## Fork and customize` — fork, edit `AGENTS.md` / `skills/`, then run the same install commands against the fork URL; a fork is its own marketplace.
7. `## Manual alternative (submodule)` — keep the existing submodule + symlink instructions and the upstream-sync snippet unchanged.
8. `## Releasing (maintainers)` — `scripts/release.sh 0.2.0` bumps the three manifests in lockstep, tags, and pushes.
9. Keep the dotfiles note and `## License` as-is.

- [ ] **Step 2: Check rendering**

Run: `grep -n 'plugin marketplace add' README.md`
Expected: hits for both the Claude Code and Codex commands.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: rewrite readme for plugin install"
```

### Task 11: End-to-end verification

No new files; this validates the installed behavior for real. Fixes discovered here go into the task that owns the broken file.

- [ ] **Step 1: Install from the local marketplace**

In a different project directory, inside Claude Code:

```
/plugin marketplace add /Users/hashiiiii/workspace/rules-for-ai
/plugin install rules-for-ai@rules-for-ai
```

Expected: install succeeds; `/plugin` lists `rules-for-ai` as enabled.

- [ ] **Step 2: Verify injection and onboarding**

Move the user config aside, then start a fresh session:

```bash
mv ~/.config/rules-for-ai/LOCALE.md /tmp/locale-backup.md 2>/dev/null || true
```

In the fresh session, confirm all three by asking Claude what context it sees:
- the `# AGENTS` principles are present at session start
- a `## Locale (resolved)` table is present with all four rows
- Claude proactively asks for locale preferences (onboarding)

- [ ] **Step 3: Verify onboarding writes and silences**

Answer the onboarding questions (e.g. `issues=ja_JP`, rest `en_US`).
Expected: `~/.config/rules-for-ai/LOCALE.md` exists with all four rows.
Start another fresh session: the resolved table shows `ja_JP` for Issues and no onboarding prompt appears.

- [ ] **Step 4: Verify project override**

In the test project: `printf '| Artifact | Language |\n|----------|----------|\n| Issues | en_GB |\n' > LOCALE.md`
Start a fresh session; expected: `| Issues | en_GB |` in the resolved table. Remove the file afterwards.

- [ ] **Step 5: Verify the skills are visible**

Run `/plugin` and confirm the plugin ships `hashiiiii-git`, `hashiiiii-issues`, and `hashiiiii-locale` skills.

- [ ] **Step 6: Restore user config**

```bash
mv /tmp/locale-backup.md ~/.config/rules-for-ai/LOCALE.md 2>/dev/null || true
```

- [ ] **Step 7: Commit any fixes discovered**

If verification forced changes, commit them in the owning task's style. Otherwise nothing to commit.
