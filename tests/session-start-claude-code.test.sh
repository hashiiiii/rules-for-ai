#!/bin/sh
# These tests cover hooks/session-start-claude-code.sh.
#
# Each case creates a real directory layout under a temporary root.
# Then it runs the hook with environment paths that point into that layout.
# These paths are CLAUDE_PLUGIN_ROOT, CLAUDE_PROJECT_DIR, and XDG_CONFIG_HOME.
# The tests do not use mocks or stubs. The hook reads real files.
#
# The hashiiiii-locale skill writes complete LOCALE files.
# Thus, each fixture contains all five keys.
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
HOOK="$REPO/hooks/session-start-claude-code.sh"
failures=0

# assert_contains <haystack> <needle> <case-description> searches the result.
assert_contains() {
    case "$1" in
        *"$2"*) printf 'PASS: %s\n' "$3" ;;
        *) printf 'FAIL: %s (missing: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
    esac
}

# assert_not_contains <haystack> <needle> <case-description> searches for an unexpected value.
assert_not_contains() {
    case "$1" in
        *"$2"*) printf 'FAIL: %s (unexpected: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
        *) printf 'PASS: %s\n' "$3" ;;
    esac
}

# new_fixture creates a temporary root with plugin, project, and locale directories.
# The plugin directory contains copies of AGENTS.md and LOCALE.default.md.
# The function prints the root path.
new_fixture() {
    fixture_root=$(mktemp -d)
    mkdir -p "$fixture_root/plugin" "$fixture_root/project" "$fixture_root/config"
    git -C "$fixture_root/project" init --quiet
    cp "$REPO/AGENTS.md" "$fixture_root/plugin/AGENTS.md"
    cp "$REPO/LOCALE.default.md" "$fixture_root/plugin/LOCALE.default.md"
    printf '%s' "$fixture_root"
}

# run_hook <fixture-root> runs the hook with the fixture layout.
run_hook() {
    printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$1/project" \
        | CLAUDE_PLUGIN_ROOT="$1/plugin" \
        CLAUDE_PROJECT_DIR="$1/missing-project" \
        XDG_CONFIG_HOME="$1/config" \
        HOME="$1" \
        sh "$HOOK"
}

# Case 1 covers fallback from the user layer to the bundled default.
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

# Case 2 makes sure that the user file wins over the bundled default.
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

# Case 3 makes sure that the hook ignores a root-level project LOCALE.md.
# The project language policy belongs in CLAUDE.md or AGENTS.md.
# It does not belong in a root-level LOCALE.md.
# This case prevents a regression in that behavior.
# If a root-level project file exists, the user file must win.
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

# In Case 4, all inputs are absent. The hook must exit 0.
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

# In Case 5, HOME and XDG_CONFIG_HOME are unset. The hook must exit 0.
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

# Case 6 makes sure that inline en_US values create a complete resolved block.
# The Cursor envelope requires a nonempty resolved block.
root=$(new_fixture)
rm "$root/plugin/LOCALE.default.md"
out=$(run_hook "$root")
assert_contains "$out" '## Locale (resolved)' 'case 6: header present without any locale file'
assert_contains "$out" 'issues=en_US' 'case 6: inline default provides issues'
assert_contains "$out" 'test-logs=en_US' 'case 6: inline default provides test-logs'
rm -rf "$root"

# Case 7 makes sure that the SessionStart cwd selects repository scopes.
# Distinct values reveal an absent input parser or an incorrect candidate order.
root=$(new_fixture)
mkdir -p "$root/project/.rules-for-ai" "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=user_USER
pull-requests=user_USER
comments=user_USER
logs=user_USER
test-logs=user_USER
EOF
cat > "$root/project/.rules-for-ai/LOCALE.md" <<'EOF'
issues=project_PROJECT
pull-requests=project_PROJECT
comments=project_PROJECT
logs=project_PROJECT
test-logs=project_PROJECT
EOF
git_dir=$(git -C "$root/project" rev-parse --absolute-git-dir)
mkdir -p "$git_dir/rules-for-ai"
cat > "$git_dir/rules-for-ai/LOCALE.md" <<'EOF'
issues=local_LOCAL
pull-requests=local_LOCAL
comments=local_LOCAL
logs=local_LOCAL
test-logs=local_LOCAL
EOF
out=$(run_hook "$root")
assert_contains "$out" 'issues=local_LOCAL' 'case 7: cwd resolves local scope'
rm "$git_dir/rules-for-ai/LOCALE.md"
out=$(run_hook "$root")
assert_contains "$out" 'issues=project_PROJECT' 'case 7: cwd resolves project scope without local'
rm -rf "$root"

# Case 8 makes sure that older hook payloads can use CLAUDE_PROJECT_DIR.
# If the JSON has no valid cwd, this fallback retains project scope.
root=$(new_fixture)
mkdir -p "$root/project/.rules-for-ai"
cat > "$root/project/.rules-for-ai/LOCALE.md" <<'EOF'
issues=project_PROJECT
pull-requests=project_PROJECT
comments=project_PROJECT
logs=project_PROJECT
test-logs=project_PROJECT
EOF
out=$(printf '{}' | CLAUDE_PLUGIN_ROOT="$root/plugin" \
    CLAUDE_PROJECT_DIR="$root/project" XDG_CONFIG_HOME="$root/config" \
    HOME="$root" sh "$HOOK")
assert_contains "$out" 'issues=project_PROJECT' 'case 8: environment fallback resolves project scope'
rm -rf "$root"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
