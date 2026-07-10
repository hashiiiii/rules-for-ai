#!/bin/sh
# Tests for hooks/session-start.sh.
#
# Each case builds a real directory layout under a temp root and runs the
# hook with CLAUDE_PLUGIN_ROOT / CLAUDE_PROJECT_DIR / XDG_CONFIG_HOME
# pointing into it. No mocks or stubs; the hook reads real files.
#
# LOCALE files are machine-written by the hashiiiii-locale skill, so the
# fixtures are complete (all five keys).
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
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

# Case 1: fallback between the user layer and the bundled default.
root=$(new_fixture)
cat > "$root/project/LOCALE.md" <<'EOF'
issues=en_GB
pull-requests=en_GB
comments=en_GB
logs=en_GB
test-logs=en_GB
EOF
out=$(run_hook "$root")
assert_contains "$out" '# AGENTS' 'case 1: always-on rules injected'
assert_contains "$out" 'issues=en_US' 'case 1: bundled default resolves'
assert_not_contains "$out" 'en_GB' 'case 1: project file is ignored without user file'
rm -rf "$root"

# Case 2: user config -> user file wins over the bundled default.
root=$(new_fixture)
mkdir -p "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=ja_JP
pull-requests=ja_JP
comments=ja_JP
logs=en_US
test-logs=en_US
EOF
out=$(run_hook "$root")
assert_contains "$out" 'issues=ja_JP' 'case 2: user file wins over default'
assert_contains "$out" 'pull-requests=ja_JP' 'case 2: pull-requests key is injected'
assert_contains "$out" 'logs=en_US' 'case 2: all five keys are injected'
rm -rf "$root"

# Case 3: a project-root LOCALE.md is ignored. The project layer was
# removed on purpose: project language policy lives in the project's own
# CLAUDE.md / AGENTS.md, not in a LOCALE file. This case is the
# regression guard for that decision — the user file must win even when
# a project file exists.
root=$(new_fixture)
mkdir -p "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=ja_JP
pull-requests=ja_JP
comments=ja_JP
logs=ja_JP
test-logs=ja_JP
EOF
cat > "$root/project/LOCALE.md" <<'EOF'
issues=en_GB
pull-requests=en_GB
comments=en_GB
logs=en_GB
test-logs=en_GB
EOF
out=$(run_hook "$root")
assert_contains "$out" 'issues=ja_JP' 'case 3: user file wins despite project file'
assert_not_contains "$out" 'en_GB' 'case 3: project file is ignored'
rm -rf "$root"

# Case 4: the hook must exit 0 even when every input is missing.
root=$(mktemp -d)
CLAUDE_PLUGIN_ROOT="$root/nope" CLAUDE_PROJECT_DIR="$root/nope" \
XDG_CONFIG_HOME="$root/nope" HOME="$root" sh "$HOOK" > /dev/null 2>&1
status=$?
if [ "$status" -eq 0 ]; then
    printf 'PASS: case 4: exit 0 with nothing available\n'
else
    printf 'FAIL: case 4: exit status %s\n' "$status"
    failures=$((failures + 1))
fi
rm -rf "$root"

# Case 5: the hook must exit 0 even when HOME and XDG_CONFIG_HOME are
# truly unset (not merely pointing at nonexistent paths).
root=$(mktemp -d)
env -u HOME -u XDG_CONFIG_HOME \
    CLAUDE_PLUGIN_ROOT="$root/nope" CLAUDE_PROJECT_DIR="$root/nope" \
    sh "$HOOK" > /dev/null 2>&1
status=$?
if [ "$status" -eq 0 ]; then
    printf 'PASS: case 5: exit 0 with HOME and XDG_CONFIG_HOME unset\n'
else
    printf 'FAIL: case 5: exit status %s\n' "$status"
    failures=$((failures + 1))
fi
rm -rf "$root"

# Case 6: no locale file anywhere -> the shared resolver's inline en_US
# default still yields a complete resolved block. A resolved block must
# never be empty; this pins the contract the Cursor wrapper relies on.
root=$(new_fixture)
rm "$root/plugin/LOCALE.default.md"
out=$(run_hook "$root")
assert_contains "$out" '## Locale (resolved)' 'case 6: header present without any locale file'
assert_contains "$out" 'issues=en_US' 'case 6: inline default provides issues'
assert_contains "$out" 'test-logs=en_US' 'case 6: inline default provides test-logs'
rm -rf "$root"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
