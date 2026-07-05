#!/bin/sh
# Tests for hooks/session-start.sh.
#
# Each case builds a real directory layout under a temp root and runs the
# hook with CLAUDE_PLUGIN_ROOT / CLAUDE_PROJECT_DIR / XDG_CONFIG_HOME
# pointing into it. No mocks or stubs; the hook reads real files.
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
