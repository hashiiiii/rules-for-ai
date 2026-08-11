#!/bin/sh
# These tests cover hooks/session-start-cursor.sh.
#
# The hook has project and user installation layouts.
# A project installation copies the hook into .cursor/rules-for-ai/.
# Its sibling files include resolve-locale.sh, json-escape.sh, and LOCALE.default.md.
# A user installation puts the hook in <clone>/hooks/.
# Its LOCALE.default.md is at the clone root.
# Each case copies the real scripts into a real layout in a temporary directory.
# The tests run the copies to prevent the repository default from hiding the test layer.
# The hook must write one {"additional_context": ...} JSON line to stdout.
# If python3 is available, it parses the JSON.
# The tests can use python3, but the hook cannot use it.
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
failures=0

# assert_contains <haystack> <needle> <case-description> searches the result.
assert_contains() {
    case "$1" in
        *"$2"*) printf 'PASS: %s\n' "$3" ;;
        *) printf 'FAIL: %s (missing: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
    esac
}

# install_scripts <dir> copies the hook and its sibling scripts into an installation layout.
install_scripts() {
    mkdir -p "$1"
    cp "$REPO/hooks/session-start-cursor.sh" "$1/session-start-cursor.sh"
    cp "$REPO/hooks/resolve-locale.sh" "$1/resolve-locale.sh"
    cp "$REPO/hooks/resolve-scoped-locale.sh" "$1/resolve-scoped-locale.sh"
    cp "$REPO/hooks/json-escape.sh" "$1/json-escape.sh"
}

# run_hook <hook-dir> <fixture-root> [workspace-root] runs the installed hook.
# It isolates the user locale files in the fixture.
run_hook() {
    workspace_root=${3:-}
    printf '{"conversation_id":"fixture","workspace_roots":["%s"]}' "$workspace_root" \
        | XDG_CONFIG_HOME="$2/config" HOME="$2" sh "$1/session-start-cursor.sh"
}

# Case 1 makes sure that the user LOCALE.md wins over the sibling default.
# The locale keys occur in additional_context on one line.
# Literal \n values represent the encoded newlines.
root=$(mktemp -d)
install_scripts "$root/.cursor/rules-for-ai"
printf 'issues=xx_XX\n' > "$root/.cursor/rules-for-ai/LOCALE.default.md"
mkdir -p "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=ja_JP
pull-requests=ja_JP
comments=ja_JP
logs=ja_JP
test-logs=ja_JP
EOF
out=$(run_hook "$root/.cursor/rules-for-ai" "$root")
assert_contains "$out" '{"additional_context":"' 'case 1: JSON envelope present'
assert_contains "$out" '## Locale (resolved)' 'case 1: resolved header in body'
assert_contains "$out" 'issues=ja_JP\npull-requests=ja_JP' 'case 1: user keys win, joined with literal backslash-n'
lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
if [ "$lines" -eq 1 ]; then
    printf 'PASS: case 1: output is a single line\n'
else
    printf 'FAIL: case 1: expected 1 line, got %s\n' "$lines"; failures=$((failures + 1))
fi
rm -rf "$root"

# Case 2 covers a project or local layout without a user file.
# The copied sibling LOCALE.default.md must win.
# The distinct tag proves that the hook read the copy and not the inline default.
root=$(mktemp -d)
install_scripts "$root/.cursor/rules-for-ai"
printf 'issues=xx_XX\npull-requests=xx_XX\ncomments=xx_XX\nlogs=xx_XX\ntest-logs=xx_XX\n' \
    > "$root/.cursor/rules-for-ai/LOCALE.default.md"
out=$(run_hook "$root/.cursor/rules-for-ai" "$root")
assert_contains "$out" 'issues=xx_XX' 'case 2: sibling LOCALE.default.md provides the keys'
rm -rf "$root"

# Case 3 covers a user plugin clone without a user file.
# The parent lookup must select the clone-root LOCALE.default.md.
root=$(mktemp -d)
install_scripts "$root/plugin/hooks"
printf 'issues=yy_YY\npull-requests=yy_YY\ncomments=yy_YY\nlogs=yy_YY\ntest-logs=yy_YY\n' \
    > "$root/plugin/LOCALE.default.md"
out=$(run_hook "$root/plugin/hooks" "$root")
assert_contains "$out" 'issues=yy_YY' 'case 3: clone-root LOCALE.default.md provides the keys'
rm -rf "$root"

# Case 4 covers a layout without a user file or LOCALE.default.md.
# Inline en_US values keep the block nonempty.
root=$(mktemp -d)
install_scripts "$root/bare"
out=$(run_hook "$root/bare" "$root")
assert_contains "$out" 'issues=en_US' 'case 4: inline default provides issues'
assert_contains "$out" 'test-logs=en_US' 'case 4: inline default provides test-logs'
rm -rf "$root"

# Case 5 makes sure that JSON escaping preserves double quotes and backslashes.
# The complete envelope must have valid JSON syntax.
root=$(mktemp -d)
install_scripts "$root/bare"
mkdir -p "$root/config/rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=en_US "quoted" back\slash
pull-requests=en_US
comments=en_US
logs=en_US
test-logs=en_US
EOF
out=$(run_hook "$root/bare" "$root")
assert_contains "$out" '\"quoted\"' 'case 5: double quotes escaped'
assert_contains "$out" 'back\\slash' 'case 5: backslash escaped'
if command -v python3 > /dev/null 2>&1; then
    if printf '%s' "$out" | python3 -c '
import json, sys
d = json.load(sys.stdin)
body = d["additional_context"]
assert "\"quoted\"" in body, body
assert "back\\slash" in body, body
assert body.startswith("## Locale (resolved)"), body
'; then
        printf 'PASS: case 5: envelope parses as JSON and round-trips\n'
    else
        printf 'FAIL: case 5: invalid JSON envelope\n'; failures=$((failures + 1))
    fi
else
    printf 'SKIP: case 5 JSON round-trip (python3 not on PATH)\n'
fi
rm -rf "$root"

# In Case 6, HOME and XDG_CONFIG_HOME are unset. The hook must exit 0.
# The hook must not stop session start.
root=$(mktemp -d)
install_scripts "$root/bare"
printf '{}' | env -u HOME -u XDG_CONFIG_HOME sh "$root/bare/session-start-cursor.sh" > /dev/null 2>&1
status=$?
if [ "$status" -eq 0 ]; then
    printf 'PASS: case 6: exit 0 with HOME and XDG_CONFIG_HOME unset\n'
else
    printf 'FAIL: case 6: exit status %s\n' "$status"; failures=$((failures + 1))
fi
rm -rf "$root"

# Case 7 makes sure that workspace_roots selects repository scopes for a user hook.
# An implementation that uses the process directory reads the plugin directory and fails.
root=$(mktemp -d)
install_scripts "$root/plugin/hooks"
project="$root/project"
mkdir -p "$project" "$root/config/rules-for-ai"
git -C "$project" init --quiet
mkdir -p "$project/.rules-for-ai"
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=user_USER
pull-requests=user_USER
comments=user_USER
logs=user_USER
test-logs=user_USER
EOF
cat > "$project/.rules-for-ai/LOCALE.md" <<'EOF'
issues=project_PROJECT
pull-requests=project_PROJECT
comments=project_PROJECT
logs=project_PROJECT
test-logs=project_PROJECT
EOF
git_dir=$(git -C "$project" rev-parse --absolute-git-dir)
mkdir -p "$git_dir/rules-for-ai"
cat > "$git_dir/rules-for-ai/LOCALE.md" <<'EOF'
issues=local_LOCAL
pull-requests=local_LOCAL
comments=local_LOCAL
logs=local_LOCAL
test-logs=local_LOCAL
EOF
out=$(run_hook "$root/plugin/hooks" "$root" "$project")
assert_contains "$out" 'issues=local_LOCAL' 'case 7: workspace root resolves local scope'
rm "$git_dir/rules-for-ai/LOCALE.md"
out=$(run_hook "$root/plugin/hooks" "$root" "$project")
assert_contains "$out" 'issues=project_PROJECT' 'case 7: workspace root resolves project scope without local'
rm -rf "$root"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
