#!/bin/sh
# Tests for rules-for-ai.sh.
#
# Each case builds a real rules-for-ai-shaped source repo and a real
# target repo under a temp root, then runs the installer against them.
# No mocks or stubs; the installer copies real files and runs real git.
#
# Coverage matrix for the Cursor installer cells:
#
#   cursor  project  case 2  .cursor/rules + skills + hooks placed
#   cursor  local    case 3  case 2 files + .git/info/exclude entries
#   cursor  user     case 5  ~/.cursor/plugins/local/<plugin> clone
#                            + ~/.cursor/hooks.json (case 9: foreign
#                            hooks.json is never touched)
#
# The source fixture uses distinctive names (rfa-test / rfa-mkt) so the
# assertions prove the installer derives names from the manifests
# instead of hard-coding them.
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
failures=0
# shellcheck source=tests/rules-for-ai-test-lib.sh
. "$REPO/tests/rules-for-ai-test-lib.sh"

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
assert_file "$tgt/.cursor/skills/hashiiiii-locale/SKILL.md" 'case 2: locale skill copied'
assert_file "$tgt/.cursor/rules-for-ai/resolve-locale.sh" 'case 2: resolver copied'
assert_file "$tgt/.cursor/rules-for-ai/resolve-scoped-locale.sh" 'case 2: scope resolver copied'
assert_file "$tgt/.cursor/rules-for-ai/session-start-cursor.sh" 'case 2: cursor session hook copied'
assert_file "$tgt/.cursor/rules-for-ai/json-escape.sh" 'case 2: json escaper copied'
assert_file "$tgt/.cursor/rules-for-ai/check-pr-template.sh" 'case 2: pr check core copied'
assert_file "$tgt/.cursor/rules-for-ai/pr-template-check-cursor.sh" 'case 2: cursor pr hook copied'
assert_file "$tgt/.cursor/rules-for-ai/LOCALE.default.md" 'case 2: locale default copied'
assert_contains "$(cat "$tgt/.cursor/hooks.json")" 'session-start-cursor.sh' 'case 2: hooks.json wires sessionStart'
assert_contains "$(cat "$tgt/.cursor/hooks.json")" 'pr-template-check-cursor.sh' 'case 2: hooks.json wires beforeShellExecution'
# The installed hooks must work exactly as Cursor invokes them: cwd is
# the project root and siblings are found via dirname "$0". An isolated
# HOME means no user LOCALE.md, so the copied LOCALE.default.md wins.
hook_home=$(mktemp -d)
out=$(cd "$tgt" && printf '{}' | HOME="$hook_home" sh .cursor/rules-for-ai/session-start-cursor.sh)
assert_contains "$out" 'issues=xx_XX' 'case 2: installed session hook resolves the copied default'
out=$(cd "$tgt" && printf '{"command":"git status","cwd":"%s"}' "$tgt" \
    | HOME="$hook_home" sh .cursor/rules-for-ai/pr-template-check-cursor.sh)
assert_contains "$out" '"permission":"allow"' 'case 2: installed pr hook allows a non-PR command'
rm -rf "$hook_home"
# Re-run is the update path: a changed source file must overwrite.
printf 'changed\n' > "$src/rules/agents.mdc"
out=$(sh "$src/rules-for-ai.sh" install cursor project "$tgt" 2>&1)
assert_not_contains "$out" 'already exists' 'case 2: re-run keeps owning hooks.json'
assert_contains "$(cat "$tgt/.cursor/rules/agents.mdc")" 'changed' 'case 2: re-run overwrites managed file'
sh "$src/rules-for-ai.sh" uninstall cursor project "$tgt" > /dev/null
assert_no_file "$tgt/.cursor/rules/agents.mdc" 'case 2: uninstall removes rule'
assert_no_file "$tgt/.cursor/skills" 'case 2: uninstall prunes empty skills dir'
assert_file "$tgt/.cursor/rules/team.mdc" 'case 2: unmanaged file survives uninstall'
assert_no_file "$tgt/.cursor/rules-for-ai" 'case 2: uninstall removes the hook dir'
assert_no_file "$tgt/.cursor/hooks.json" 'case 2: uninstall removes the hooks.json it created'
rm -rf "$src" "$tgt"

# Case 3: cursor local = project files + .git/info/exclude entries,
# deduplicated on re-run and removed again on uninstall.
src=$(new_source_repo)
tgt=$(new_target_repo)
sh "$src/rules-for-ai.sh" install cursor local "$tgt" > /dev/null
exclude="$tgt/.git/info/exclude"
assert_contains "$(cat "$exclude")" '.cursor/rules/agents.mdc' 'case 3: exclude lists the rule'
assert_contains "$(cat "$exclude")" '.cursor/skills/hashiiiii-git' 'case 3: exclude lists a skill'
assert_contains "$(cat "$exclude")" '.cursor/skills/hashiiiii-locale' 'case 3: exclude lists the locale skill'
assert_contains "$(cat "$exclude")" '.cursor/rules-for-ai/session-start-cursor.sh' 'case 3: exclude lists the cursor hook'
assert_contains "$(cat "$exclude")" '.cursor/rules-for-ai/LOCALE.default.md' 'case 3: exclude lists the locale default'
assert_contains "$(cat "$exclude")" '.cursor/hooks.json' 'case 3: exclude lists the hooks.json we created'
sh "$src/rules-for-ai.sh" install cursor local "$tgt" > /dev/null
dups=$(grep -cxF '.cursor/rules/agents.mdc' "$exclude")
if [ "$dups" -eq 1 ]; then
    printf 'PASS: case 3: re-run does not duplicate exclude entries\n'
else
    printf 'FAIL: case 3: exclude entry appears %s times\n' "$dups"; failures=$((failures + 1))
fi
sh "$src/rules-for-ai.sh" uninstall cursor local "$tgt" > /dev/null
assert_not_contains "$(cat "$exclude")" '.cursor/rules/agents.mdc' 'case 3: uninstall cleans exclude'
assert_not_contains "$(cat "$exclude")" '.cursor/hooks.json' 'case 3: uninstall cleans the hooks.json exclude'
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

# Case 5: cursor user clones under a fixture HOME, wires the user-level
# hooks.json, pulls on re-run, and removes both on uninstall. The
# rfa-test directory name proves the plugin name came from the fixture
# manifest, not a hard-coded string.
src=$(new_source_repo)
home=$(mktemp -d)
HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" install cursor user > /dev/null
dest="$home/.cursor/plugins/local/rfa-test"
assert_file "$dest/rules/agents.mdc" 'case 5: clone lands under fixture HOME'
hooks="$home/.cursor/hooks.json"
assert_file "$hooks" 'case 5: user hooks.json written when absent'
assert_contains "$(cat "$hooks")" "$dest/hooks/session-start-cursor.sh" 'case 5: sessionStart carries an absolute clone path'
assert_contains "$(cat "$hooks")" "$dest/hooks/pr-template-check-cursor.sh" 'case 5: beforeShellExecution carries an absolute clone path'
# The wired hooks must work exactly as Cursor invokes user-level hooks:
# cwd is ~/.cursor, siblings and the clone-root LOCALE.default.md are
# found relative to the script itself.
out=$(cd "$home/.cursor" && printf '{}' | HOME="$home" sh "$dest/hooks/session-start-cursor.sh")
assert_contains "$out" 'issues=xx_XX' 'case 5: wired session hook resolves the clone default'
# Update path: a new commit in the source must arrive via pull, and a
# re-run must keep owning the hooks.json without warning.
printf 'v2\n' >> "$src/rules/agents.mdc"
git_q -C "$src" commit --quiet -am 'v2'
out=$(HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" install cursor user 2>&1)
assert_contains "$(cat "$dest/rules/agents.mdc")" 'v2' 'case 5: re-run pulls updates'
assert_not_contains "$out" 'already exists' 'case 5: re-run keeps owning the user hooks.json'
HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" uninstall cursor user > /dev/null
assert_no_file "$dest" 'case 5: uninstall removes the clone'
assert_no_file "$hooks" 'case 5: uninstall removes the hooks.json it created'
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
# macOS can create an xcrun_db file in TMPDIR. Only a directory can be
# the temporary clone that the installer must remove.
if [ -z "$(find "$work" -mindepth 1 -maxdepth 1 -type d -print -quit)" ]; then
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

# Case 8: a pre-existing .cursor/hooks.json is never modified -- it may
# belong to the team. Install warns and prints the entry to add
# manually; uninstall leaves the file alone.
src=$(new_source_repo)
tgt=$(new_target_repo)
mkdir -p "$tgt/.cursor"
printf '{ "version": 1, "hooks": {} }\n' > "$tgt/.cursor/hooks.json"
out=$(sh "$src/rules-for-ai.sh" install cursor project "$tgt" 2>&1)
assert_contains "$out" 'already exists' 'case 8: install warns on a foreign hooks.json'
assert_contains "$out" 'session-start-cursor.sh' 'case 8: warning shows the entry to add'
assert_contains "$(cat "$tgt/.cursor/hooks.json")" '"hooks": {}' 'case 8: foreign hooks.json untouched'
out=$(sh "$src/rules-for-ai.sh" uninstall cursor project "$tgt" 2>&1)
assert_file "$tgt/.cursor/hooks.json" 'case 8: uninstall leaves the foreign hooks.json'
# When a developer pasted our entry into their own hooks.json, the file
# is not byte-identical to ours, so uninstall must not delete it -- it
# warns to remove the entry manually instead.
printf '{ "version": 1, "hooks": { "sessionStart": [ { "command": "sh .cursor/rules-for-ai/session-start-cursor.sh" } ], "afterEdit": [] } }\n' > "$tgt/.cursor/hooks.json"
sh "$src/rules-for-ai.sh" install cursor project "$tgt" > /dev/null 2>&1
out=$(sh "$src/rules-for-ai.sh" uninstall cursor project "$tgt" 2>&1)
assert_contains "$out" 'manually' 'case 8: uninstall warns when our entry is embedded elsewhere'
assert_file "$tgt/.cursor/hooks.json" 'case 8: embedded-entry hooks.json preserved'
rm -rf "$src" "$tgt"

# Case 9: a pre-existing ~/.cursor/hooks.json (another tool may own
# it) is never modified at user scope -- install warns with the entries
# to add manually, and uninstall leaves the file alone.
src=$(new_source_repo)
home=$(mktemp -d)
mkdir -p "$home/.cursor"
printf '{ "version": 1, "hooks": { "sessionStart": [ { "command": "herdr" } ] } }\n' > "$home/.cursor/hooks.json"
out=$(HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" install cursor user 2>&1)
assert_contains "$out" 'already exists' 'case 9: install warns on a foreign user hooks.json'
assert_contains "$out" 'session-start-cursor.sh' 'case 9: warning shows the entries to add'
assert_contains "$(cat "$home/.cursor/hooks.json")" 'herdr' 'case 9: foreign user hooks.json untouched'
HOME="$home" RULES_FOR_AI_SOURCE="$src" sh "$src/rules-for-ai.sh" uninstall cursor user > /dev/null 2>&1
assert_file "$home/.cursor/hooks.json" 'case 9: uninstall leaves the foreign user hooks.json'
assert_contains "$(cat "$home/.cursor/hooks.json")" 'herdr' 'case 9: foreign content survives uninstall'
rm -rf "$src" "$home"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
