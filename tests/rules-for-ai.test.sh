#!/bin/sh
# Tests for rules-for-ai.sh.
#
# Each case builds a real rules-for-ai-shaped source repo and a real
# target repo under a temp root, then runs the installer against them.
# No mocks or stubs; the installer copies real files and runs real git.
#
# Coverage matrix -- every {platform} x {scope} cell is guaranteed:
#
#   cursor  project  case 2  .cursor/rules + .cursor/skills placed
#   cursor  local    case 3  case 2 files + .git/info/exclude entries
#   cursor  user     case 5  ~/.cursor/plugins/local/<plugin> clone
#   claude  project  case 8  .claude/settings.json enables the plugin
#   claude  local    case 8  .claude/settings.local.json enables it
#   claude  user     case 8  ~/.claude/settings.json enables it
#
# The source fixture uses distinctive names (rfa-test / rfa-mkt) so the
# assertions prove the installer derives names from the manifests
# instead of hard-coding them.
#
# The claude cells shell out to the real `claude` CLI. That end-to-end
# case writes to the machine's real plugin cache, so it is opt-in:
# RULES_FOR_AI_E2E=1 plus `claude` on PATH (CI sets both).
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
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

# assert_file <path> <case description>
assert_file() {
    if [ -e "$1" ]; then
        printf 'PASS: %s\n' "$2"
    else
        printf 'FAIL: %s (missing: %s)\n' "$2" "$1"; failures=$((failures + 1))
    fi
}

# assert_no_file <path> <case description>
assert_no_file() {
    if [ -e "$1" ]; then
        printf 'FAIL: %s (still exists: %s)\n' "$2" "$1"; failures=$((failures + 1))
    else
        printf 'PASS: %s\n' "$2"
    fi
}

# git with a throwaway identity so commits work on bare CI machines.
git_q() { git -c user.email=test@test.invalid -c user.name=test "$@"; }

# new_source_repo: minimal rules-for-ai-shaped repo with the real
# rules-for-ai.sh copied in, committed so it can be cloned. Prints its path.
new_source_repo() {
    src=$(mktemp -d)
    mkdir -p "$src/.claude-plugin" "$src/rules" \
        "$src/skills/hashiiiii-git" "$src/skills/hashiiiii-issues" \
        "$src/skills/hashiiiii-locale"
    cat > "$src/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "rfa-test",
  "version": "0.0.1",
  "description": "fixture"
}
EOF
    cat > "$src/.claude-plugin/marketplace.json" <<'EOF'
{
  "name": "rfa-mkt",
  "owner": { "name": "fixture" },
  "plugins": [{ "name": "rfa-test", "source": "./" }]
}
EOF
    printf -- '---\nalwaysApply: true\n---\n# AGENTS fixture\n' > "$src/rules/agents.mdc"
    printf '# git skill fixture\n' > "$src/skills/hashiiiii-git/SKILL.md"
    printf '# issues skill fixture\n' > "$src/skills/hashiiiii-issues/SKILL.md"
    printf '# locale skill fixture\n' > "$src/skills/hashiiiii-locale/SKILL.md"
    cp "$REPO/rules-for-ai.sh" "$src/rules-for-ai.sh"
    git_q -C "$src" init --quiet
    git_q -C "$src" add -A
    git_q -C "$src" commit --quiet -m fixture
    printf '%s' "$src"
}

# new_target_repo: empty git repo standing in for a user project.
new_target_repo() {
    tgt=$(mktemp -d)
    git_q -C "$tgt" init --quiet
    printf '%s' "$tgt"
}

# Case 1: argument validation fails fast with a non-zero exit.
src=$(new_source_repo)
if sh "$src/rules-for-ai.sh" > /dev/null 2>&1; then
    printf 'FAIL: case 1: no arguments must fail\n'; failures=$((failures + 1))
else
    printf 'PASS: case 1: no arguments must fail\n'
fi
if sh "$src/rules-for-ai.sh" frobnicate cursor user > /dev/null 2>&1; then
    printf 'FAIL: case 1: unknown verb must fail\n'; failures=$((failures + 1))
else
    printf 'PASS: case 1: unknown verb must fail\n'
fi
if sh "$src/rules-for-ai.sh" install emacs user > /dev/null 2>&1; then
    printf 'FAIL: case 1: unknown platform must fail\n'; failures=$((failures + 1))
else
    printf 'PASS: case 1: unknown platform must fail\n'
fi
if sh "$src/rules-for-ai.sh" install claude global > /dev/null 2>&1; then
    printf 'FAIL: case 1: unknown scope must fail\n'; failures=$((failures + 1))
else
    printf 'PASS: case 1: unknown scope must fail\n'
fi
out=$(sh "$src/rules-for-ai.sh" install cursor user /tmp 2>&1) && :
assert_contains "$out" 'target-dir does not apply' 'case 1: user scope rejects target-dir'
# help is an explicit request: usage to stdout, exit 0.
out=$(sh "$src/rules-for-ai.sh" help) && rc=0 || rc=$?
assert_contains "$out" 'usage:' 'case 1: help prints usage'
if [ "${rc:-1}" -eq 0 ]; then
    printf 'PASS: case 1: help exits 0\n'
else
    printf 'FAIL: case 1: help exits non-zero (%s)\n' "$rc"; failures=$((failures + 1))
fi
rm -rf "$src"

# Case 2: cursor project install / update / uninstall. An unmanaged
# file sits next to the managed ones to prove the installer never
# touches anything it did not create.
src=$(new_source_repo)
tgt=$(new_target_repo)
mkdir -p "$tgt/.cursor/rules"
printf 'team rule\n' > "$tgt/.cursor/rules/team.mdc"
sh "$src/rules-for-ai.sh" install cursor project "$tgt" > /dev/null
assert_file "$tgt/.cursor/rules/agents.mdc" 'case 2: rule copied'
assert_file "$tgt/.cursor/skills/hashiiiii-git/SKILL.md" 'case 2: git skill copied'
assert_file "$tgt/.cursor/skills/hashiiiii-issues/SKILL.md" 'case 2: issues skill copied'
assert_no_file "$tgt/.cursor/skills/hashiiiii-locale" 'case 2: locale skill excluded'
# Re-run is the update path: a changed source file must overwrite.
printf 'changed\n' > "$src/rules/agents.mdc"
sh "$src/rules-for-ai.sh" install cursor project "$tgt" > /dev/null
assert_contains "$(cat "$tgt/.cursor/rules/agents.mdc")" 'changed' 'case 2: re-run overwrites managed file'
sh "$src/rules-for-ai.sh" uninstall cursor project "$tgt" > /dev/null
assert_no_file "$tgt/.cursor/rules/agents.mdc" 'case 2: uninstall removes rule'
assert_no_file "$tgt/.cursor/skills" 'case 2: uninstall prunes empty skills dir'
assert_file "$tgt/.cursor/rules/team.mdc" 'case 2: unmanaged file survives uninstall'
rm -rf "$src" "$tgt"

# Case 3: cursor local = project files + .git/info/exclude entries,
# deduplicated on re-run and removed again on uninstall.
src=$(new_source_repo)
tgt=$(new_target_repo)
sh "$src/rules-for-ai.sh" install cursor local "$tgt" > /dev/null
exclude="$tgt/.git/info/exclude"
assert_contains "$(cat "$exclude")" '.cursor/rules/agents.mdc' 'case 3: exclude lists the rule'
assert_contains "$(cat "$exclude")" '.cursor/skills/hashiiiii-git' 'case 3: exclude lists a skill'
sh "$src/rules-for-ai.sh" install cursor local "$tgt" > /dev/null
dups=$(grep -cxF '.cursor/rules/agents.mdc' "$exclude")
if [ "$dups" -eq 1 ]; then
    printf 'PASS: case 3: re-run does not duplicate exclude entries\n'
else
    printf 'FAIL: case 3: exclude entry appears %s times\n' "$dups"; failures=$((failures + 1))
fi
sh "$src/rules-for-ai.sh" uninstall cursor local "$tgt" > /dev/null
assert_not_contains "$(cat "$exclude")" '.cursor/rules/agents.mdc' 'case 3: uninstall cleans exclude'
assert_no_file "$tgt/.cursor" 'case 3: uninstall removes files'
rm -rf "$src" "$tgt"

# Case 4: local scope cannot hide an already-tracked file; the installer
# must warn and point at project scope instead.
src=$(new_source_repo)
tgt=$(new_target_repo)
sh "$src/rules-for-ai.sh" install cursor project "$tgt" > /dev/null
git_q -C "$tgt" add -A
git_q -C "$tgt" commit --quiet -m 'adopt project scope'
out=$(sh "$src/rules-for-ai.sh" install cursor local "$tgt" 2>&1)
assert_contains "$out" 'already tracked' 'case 4: tracked file warning'
rm -rf "$src" "$tgt"

# Case 5: cursor user clones under a fixture HOME, pulls on re-run, and
# removes on uninstall. The rfa-test directory name proves the plugin
# name came from the fixture manifest, not a hard-coded string.
src=$(new_source_repo)
home=$(mktemp -d)
HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" install cursor user > /dev/null
dest="$home/.cursor/plugins/local/rfa-test"
assert_file "$dest/rules/agents.mdc" 'case 5: clone lands under fixture HOME'
# Update path: a new commit in the source must arrive via pull.
printf 'v2\n' >> "$src/rules/agents.mdc"
git_q -C "$src" commit --quiet -am 'v2'
HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" install cursor user > /dev/null
assert_contains "$(cat "$dest/rules/agents.mdc")" 'v2' 'case 5: re-run pulls updates'
HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" uninstall cursor user > /dev/null
assert_no_file "$dest" 'case 5: uninstall removes the clone'
rm -rf "$src" "$home"

# Case 6: curl mode. The script runs from a bare directory (as if piped
# from curl), self-fetches the repo from RULES_FOR_AI_SOURCE into
# TMPDIR, installs, and cleans the temp clone up on exit.
src=$(new_source_repo)
tgt=$(new_target_repo)
outside=$(mktemp -d)
cp "$REPO/rules-for-ai.sh" "$outside/rules-for-ai.sh"
work="$outside/tmpwork"
mkdir "$work"
TMPDIR="$work" RULES_FOR_AI_SOURCE="$src" sh "$outside/rules-for-ai.sh" install cursor project "$tgt" > /dev/null
assert_file "$tgt/.cursor/rules/agents.mdc" 'case 6: curl mode installs'
if [ -z "$(ls -A "$work")" ]; then
    printf 'PASS: case 6: temp clone cleaned up on exit\n'
else
    printf 'FAIL: case 6: temp clone left behind in %s\n' "$work"; failures=$((failures + 1))
fi
rm -rf "$src" "$tgt" "$outside"

# Case 7: the installer must refuse to target its own repo (the
# run-from-clone footgun).
src=$(new_source_repo)
out=$(sh "$src/rules-for-ai.sh" install cursor project "$src" 2>&1) && :
assert_contains "$out" 'itself' 'case 7: refuses to target the source repo'
rm -rf "$src"

# Case 8: claude cells at every scope, end to end against the real
# `claude` CLI. Each scope writes a different settings file; the asserts
# pin the plugin to the file its scope must use. This writes to the real
# plugin cache under $HOME, so it is opt-in: RULES_FOR_AI_E2E=1 plus
# `claude` on PATH (CI sets both).
if [ "${RULES_FOR_AI_E2E:-}" = 1 ] && command -v claude > /dev/null 2>&1; then
    src=$(new_source_repo)
    tgt=$(new_target_repo)
    # project scope -> the repo's .claude/settings.json (committed).
    RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" install claude project "$tgt" > /dev/null
    settings="$tgt/.claude/settings.json"
    assert_file "$settings" 'case 8: project settings written'
    assert_contains "$(cat "$settings")" '"rfa-test@rfa-mkt": true' 'case 8: project scope enables plugin in settings.json'
    RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" uninstall claude project "$tgt" > /dev/null
    assert_not_contains "$(cat "$settings")" '"rfa-test@rfa-mkt": true' 'case 8: uninstall disables plugin at project scope'
    # local scope -> the repo's .claude/settings.local.json (gitignored).
    RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" install claude local "$tgt" > /dev/null
    assert_contains "$(cat "$tgt/.claude/settings.local.json")" '"rfa-test@rfa-mkt": true' 'case 8: local scope enables plugin in settings.local.json'
    RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" uninstall claude local "$tgt" > /dev/null
    # user scope -> ~/.claude/settings.json. It is HOME-based, not
    # repo-based, so a fixture HOME isolates the machine's real config.
    home=$(mktemp -d)
    HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" install claude user > /dev/null
    assert_contains "$(cat "$home/.claude/settings.json")" '"rfa-test@rfa-mkt": true' 'case 8: user scope enables plugin in ~/.claude/settings.json'
    HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" uninstall claude user > /dev/null
    assert_not_contains "$(cat "$home/.claude/settings.json")" '"rfa-test@rfa-mkt": true' 'case 8: uninstall disables plugin at user scope'
    rm -rf "$src" "$tgt" "$home"
else
    printf 'SKIP: case 8: claude e2e (set RULES_FOR_AI_E2E=1 with claude on PATH)\n'
fi

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
