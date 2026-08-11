#!/bin/sh
# These tests cover the Codex installer cells.
#
# Each case uses real source and target repositories in temporary directories.
# The tests verify updates, ownership checks, and Git exclusions without mocks.
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
failures=0
# shellcheck source=tests/rules-for-ai-test-lib.sh
. "$REPO/tests/rules-for-ai-test-lib.sh"

# Case 1 covers user installation, update, and removal with a custom CODEX_HOME.
# An unmanaged skill proves that removal only changes installer-owned paths.
src=$(new_source_repo)
home=$(mktemp -d)
codex_home="$home/codex-home"
mkdir -p "$home/.agents/skills/team-skill"
printf '# team skill\n' > "$home/.agents/skills/team-skill/SKILL.md"
HOME="$home" CODEX_HOME="$codex_home" sh "$src/rules-for-ai.sh" install codex user > /dev/null
assert_file "$codex_home/AGENTS.md" 'case 1: user rule installed'
assert_file "$codex_home/rules-for-ai/AGENTS.md" 'case 1: user ownership copy installed'
assert_file "$codex_home/rules-for-ai/LOCALE.default.md" 'case 1: user locale default installed'
assert_file "$home/.agents/skills/hashiiiii-git/SKILL.md" 'case 1: user Git skill installed'
printf '# AGENTS fixture v2\n' > "$src/AGENTS.md"
printf '# Git skill fixture v2\n' > "$src/skills/hashiiiii-git/SKILL.md"
HOME="$home" CODEX_HOME="$codex_home" sh "$src/rules-for-ai.sh" install codex user > /dev/null
assert_contains "$(cat "$codex_home/AGENTS.md")" 'fixture v2' 'case 1: user rule updated'
assert_contains "$(cat "$home/.agents/skills/hashiiiii-git/SKILL.md")" 'fixture v2' \
    'case 1: user Git skill updated'
HOME="$home" CODEX_HOME="$codex_home" sh "$src/rules-for-ai.sh" uninstall codex user > /dev/null
assert_no_file "$codex_home/AGENTS.md" 'case 1: user rule removed'
assert_no_file "$codex_home/rules-for-ai" 'case 1: user support directory removed'
assert_no_file "$home/.agents/skills/hashiiiii-git" 'case 1: user Git skill removed'
assert_file "$home/.agents/skills/team-skill/SKILL.md" 'case 1: unmanaged user skill preserved'
rm -rf "$src" "$home"

# Case 2 covers project installation, update, and removal.
# The ownership copy lets an update replace only an unchanged managed rule.
src=$(new_source_repo)
tgt=$(new_target_repo)
mkdir -p "$tgt/.agents/skills/team-skill"
printf '# team skill\n' > "$tgt/.agents/skills/team-skill/SKILL.md"
sh "$src/rules-for-ai.sh" install codex project "$tgt" > /dev/null
assert_file "$tgt/AGENTS.md" 'case 2: project rule installed'
assert_file "$tgt/.agents/rules-for-ai/AGENTS.md" 'case 2: project ownership copy installed'
assert_file "$tgt/.agents/rules-for-ai/LOCALE.default.md" 'case 2: project locale default installed'
assert_file "$tgt/.agents/skills/hashiiiii-issues/SKILL.md" 'case 2: project issue skill installed'
printf '# AGENTS fixture v2\n' > "$src/AGENTS.md"
sh "$src/rules-for-ai.sh" install codex project "$tgt" > /dev/null
assert_contains "$(cat "$tgt/AGENTS.md")" 'fixture v2' 'case 2: project rule updated'
sh "$src/rules-for-ai.sh" uninstall codex project "$tgt" > /dev/null
assert_no_file "$tgt/AGENTS.md" 'case 2: project rule removed'
assert_no_file "$tgt/.agents/rules-for-ai" 'case 2: project support directory removed'
assert_no_file "$tgt/.agents/skills/hashiiiii-issues" 'case 2: project issue skill removed'
assert_file "$tgt/.agents/skills/team-skill/SKILL.md" 'case 2: unmanaged project skill preserved'
rm -rf "$src" "$tgt"

# Case 3 covers local installation and Git exclusions.
# A second installation must not duplicate any exclusion.
src=$(new_source_repo)
tgt=$(new_target_repo)
sh "$src/rules-for-ai.sh" install codex local "$tgt" > /dev/null
exclude="$tgt/.git/info/exclude"
assert_contains "$(cat "$exclude")" '/AGENTS.md' 'case 3: local rule excluded'
assert_contains "$(cat "$exclude")" '.agents/rules-for-ai' 'case 3: local support directory excluded'
assert_contains "$(cat "$exclude")" '.agents/skills/hashiiiii-git' 'case 3: local Git skill excluded'
mkdir -p "$tgt/service"
printf '# Service instructions\n' > "$tgt/service/AGENTS.md"
assert_contains "$(git -C "$tgt" status --short --untracked-files=all)" 'service/AGENTS.md' \
    'case 3: root exclusion does not hide a nested rule'
sh "$src/rules-for-ai.sh" install codex local "$tgt" > /dev/null
dups=$(grep -cxF '/AGENTS.md' "$exclude")
if [ "$dups" -eq 1 ]; then
    printf 'PASS: case 3: re-run does not duplicate rule exclusion\n'
else
    printf 'FAIL: case 3: rule exclusion appears %s times\n' "$dups"
    failures=$((failures + 1))
fi
sh "$src/rules-for-ai.sh" uninstall codex local "$tgt" > /dev/null
assert_not_contains "$(cat "$exclude")" '/AGENTS.md' 'case 3: local rule exclusion removed'
assert_not_contains "$(cat "$exclude")" '.agents/rules-for-ai' 'case 3: local support exclusion removed'
assert_no_file "$tgt/.agents" 'case 3: empty local agent directory removed'
rm -rf "$src" "$tgt"

# Case 4 proves that a foreign project rule remains unchanged.
# Install still adds skills and prints the manual integration path.
src=$(new_source_repo)
tgt=$(new_target_repo)
printf '# Team instructions\n' > "$tgt/AGENTS.md"
out=$(sh "$src/rules-for-ai.sh" install codex project "$tgt" 2>&1)
assert_contains "$out" 'already exists' 'case 4: foreign project rule causes a warning'
assert_contains "$out" "$src/AGENTS.md" 'case 4: warning identifies the source rule'
assert_contains "$(cat "$tgt/AGENTS.md")" 'Team instructions' 'case 4: foreign project rule preserved'
assert_file "$tgt/.agents/skills/hashiiiii-locale/SKILL.md" 'case 4: skills install beside a foreign rule'
sh "$src/rules-for-ai.sh" uninstall codex project "$tgt" > /dev/null
assert_file "$tgt/AGENTS.md" 'case 4: foreign project rule survives uninstall'
rm -rf "$src" "$tgt"

# Case 5 proves that a modified managed rule remains after removal.
src=$(new_source_repo)
home=$(mktemp -d)
HOME="$home" sh "$src/rules-for-ai.sh" install codex user > /dev/null
printf '\n# Personal addition\n' >> "$home/.codex/AGENTS.md"
out=$(HOME="$home" sh "$src/rules-for-ai.sh" uninstall codex user 2>&1)
assert_contains "$out" 'was modified' 'case 5: modified user rule causes a warning'
assert_file "$home/.codex/AGENTS.md" 'case 5: modified user rule survives uninstall'
assert_contains "$(cat "$home/.codex/AGENTS.md")" 'Personal addition' 'case 5: user addition preserved'
rm -rf "$src" "$home"

# Case 6 proves that matching content does not imply installer ownership.
# A foreign rule and a foreign same-name skill must survive every operation.
src=$(new_source_repo)
home=$(mktemp -d)
mkdir -p "$home/.codex" "$home/.agents/skills/hashiiiii-git"
cp "$src/AGENTS.md" "$home/.codex/AGENTS.md"
printf '# personal Git skill\n' > "$home/.agents/skills/hashiiiii-git/SKILL.md"
out=$(HOME="$home" sh "$src/rules-for-ai.sh" install codex user 2>&1)
assert_contains "$out" 'already exists' 'case 6: matching foreign rule causes a warning'
assert_no_file "$home/.codex/rules-for-ai/AGENTS.md" 'case 6: matching foreign rule is not claimed'
assert_contains "$(cat "$home/.agents/skills/hashiiiii-git/SKILL.md")" 'personal Git skill' \
    'case 6: foreign same-name skill is not overwritten'
HOME="$home" sh "$src/rules-for-ai.sh" uninstall codex user > /dev/null 2>&1
assert_file "$home/.codex/AGENTS.md" 'case 6: matching foreign rule survives uninstall'
assert_file "$home/.agents/skills/hashiiiii-git/SKILL.md" 'case 6: foreign same-name skill survives uninstall'
rm -rf "$src" "$home"

# Case 7 proves that removal preserves a managed skill after a user changes it.
src=$(new_source_repo)
home=$(mktemp -d)
HOME="$home" sh "$src/rules-for-ai.sh" install codex user > /dev/null
printf '\n# Personal skill addition\n' >> "$home/.agents/skills/hashiiiii-git/SKILL.md"
out=$(HOME="$home" sh "$src/rules-for-ai.sh" uninstall codex user 2>&1)
assert_contains "$out" 'was modified' 'case 7: modified skill causes a warning'
assert_file "$home/.agents/skills/hashiiiii-git/SKILL.md" 'case 7: modified skill survives uninstall'
assert_contains "$(cat "$home/.agents/skills/hashiiiii-git/SKILL.md")" 'Personal skill addition' \
    'case 7: personal skill addition is preserved'
rm -rf "$src" "$home"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
