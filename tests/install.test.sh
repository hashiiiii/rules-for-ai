#!/bin/sh
# Tests for install.sh.
#
# Each case builds a real rules-for-ai-shaped source repo and a real
# target repo under a temp root, then runs the installer against them.
# No mocks or stubs; the installer copies real files and runs real git.
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
# install.sh copied in, committed so it can be cloned. Prints its path.
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
    cp "$REPO/install.sh" "$src/install.sh"
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
if sh "$src/install.sh" > /dev/null 2>&1; then
    printf 'FAIL: case 1: no arguments must fail\n'; failures=$((failures + 1))
else
    printf 'PASS: case 1: no arguments must fail\n'
fi
if sh "$src/install.sh" emacs user > /dev/null 2>&1; then
    printf 'FAIL: case 1: unknown platform must fail\n'; failures=$((failures + 1))
else
    printf 'PASS: case 1: unknown platform must fail\n'
fi
if sh "$src/install.sh" claude global > /dev/null 2>&1; then
    printf 'FAIL: case 1: unknown scope must fail\n'; failures=$((failures + 1))
else
    printf 'PASS: case 1: unknown scope must fail\n'
fi
out=$(sh "$src/install.sh" cursor user /tmp 2>&1) && :
assert_contains "$out" 'target-dir does not apply' 'case 1: user scope rejects target-dir'
rm -rf "$src"

# Case 2: cursor project install / update / uninstall. An unmanaged
# file sits next to the managed ones to prove the installer never
# touches anything it did not create.
src=$(new_source_repo)
tgt=$(new_target_repo)
mkdir -p "$tgt/.cursor/rules"
printf 'team rule\n' > "$tgt/.cursor/rules/team.mdc"
sh "$src/install.sh" cursor project "$tgt" > /dev/null
assert_file "$tgt/.cursor/rules/agents.mdc" 'case 2: rule copied'
assert_file "$tgt/.cursor/skills/hashiiiii-git/SKILL.md" 'case 2: git skill copied'
assert_file "$tgt/.cursor/skills/hashiiiii-issues/SKILL.md" 'case 2: issues skill copied'
assert_no_file "$tgt/.cursor/skills/hashiiiii-locale" 'case 2: locale skill excluded'
# Re-run is the update path: a changed source file must overwrite.
printf 'changed\n' > "$src/rules/agents.mdc"
sh "$src/install.sh" cursor project "$tgt" > /dev/null
assert_contains "$(cat "$tgt/.cursor/rules/agents.mdc")" 'changed' 'case 2: re-run overwrites managed file'
sh "$src/install.sh" --uninstall cursor project "$tgt" > /dev/null
assert_no_file "$tgt/.cursor/rules/agents.mdc" 'case 2: uninstall removes rule'
assert_no_file "$tgt/.cursor/skills" 'case 2: uninstall prunes empty skills dir'
assert_file "$tgt/.cursor/rules/team.mdc" 'case 2: unmanaged file survives uninstall'
rm -rf "$src" "$tgt"

# Case 3: cursor local = project files + .git/info/exclude entries,
# deduplicated on re-run and removed again on uninstall.
src=$(new_source_repo)
tgt=$(new_target_repo)
sh "$src/install.sh" cursor local "$tgt" > /dev/null
exclude="$tgt/.git/info/exclude"
assert_contains "$(cat "$exclude")" '.cursor/rules/agents.mdc' 'case 3: exclude lists the rule'
assert_contains "$(cat "$exclude")" '.cursor/skills/hashiiiii-git' 'case 3: exclude lists a skill'
sh "$src/install.sh" cursor local "$tgt" > /dev/null
dups=$(grep -cxF '.cursor/rules/agents.mdc' "$exclude")
if [ "$dups" -eq 1 ]; then
    printf 'PASS: case 3: re-run does not duplicate exclude entries\n'
else
    printf 'FAIL: case 3: exclude entry appears %s times\n' "$dups"; failures=$((failures + 1))
fi
sh "$src/install.sh" --uninstall cursor local "$tgt" > /dev/null
assert_not_contains "$(cat "$exclude")" '.cursor/rules/agents.mdc' 'case 3: uninstall cleans exclude'
assert_no_file "$tgt/.cursor" 'case 3: uninstall removes files'
rm -rf "$src" "$tgt"

# Case 4: local scope cannot hide an already-tracked file; the installer
# must warn and point at project scope instead.
src=$(new_source_repo)
tgt=$(new_target_repo)
sh "$src/install.sh" cursor project "$tgt" > /dev/null
git_q -C "$tgt" add -A
git_q -C "$tgt" commit --quiet -m 'adopt project scope'
out=$(sh "$src/install.sh" cursor local "$tgt" 2>&1)
assert_contains "$out" 'already tracked' 'case 4: tracked file warning'
rm -rf "$src" "$tgt"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
