#!/bin/sh
# Tests for hooks/resolve-locale.sh.
#
# The resolver is the single source of locale resolution logic shared
# by the Claude and Cursor session-start wrappers: first existing
# candidate wins as a whole, inline en_US when none exists. Each case
# runs the real script against real files under a temp root; no mocks
# or stubs.
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
RESOLVER="$REPO/hooks/resolve-locale.sh"
SCOPED_RESOLVER="$REPO/hooks/resolve-scoped-locale.sh"
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

root=$(mktemp -d)
cat > "$root/first.md" <<'EOF'
issues=ja_JP
pull-requests=ja_JP
comments=ja_JP
logs=ja_JP
test-logs=ja_JP
EOF
cat > "$root/second.md" <<'EOF'
issues=en_GB
pull-requests=en_GB
comments=en_GB
logs=en_GB
test-logs=en_GB
EOF

# Case 1: the first existing candidate wins as a whole; later
# candidates never merge in.
out=$(sh "$RESOLVER" "$root/first.md" "$root/second.md")
assert_contains "$out" 'issues=ja_JP' 'case 1: first candidate wins'
assert_not_contains "$out" 'en_GB' 'case 1: layers never merge'

# Case 2: a missing first candidate falls through to the second.
out=$(sh "$RESOLVER" "$root/missing.md" "$root/second.md")
assert_contains "$out" 'issues=en_GB' 'case 2: falls through to the next candidate'

# Case 3: prose around the keys is filtered out. The real bundled
# LOCALE.default.md carries explanatory text above the keys; only the
# five key lines may pass through.
out=$(sh "$RESOLVER" "$REPO/LOCALE.default.md")
assert_contains "$out" 'issues=en_US' 'case 3: bundled default resolves'
assert_not_contains "$out" '# Locale' 'case 3: prose is filtered'
lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
if [ "$lines" -eq 5 ]; then
    printf 'PASS: case 3: exactly five key lines\n'
else
    printf 'FAIL: case 3: expected 5 lines, got %s\n' "$lines"; failures=$((failures + 1))
fi

# Case 4: no candidate exists -> the inline en_US default provides all
# five keys, so a resolved block is never empty.
out=$(sh "$RESOLVER" "$root/missing.md")
assert_contains "$out" 'issues=en_US' 'case 4: inline default provides issues'
assert_contains "$out" 'pull-requests=en_US' 'case 4: inline default provides pull-requests'
assert_contains "$out" 'comments=en_US' 'case 4: inline default provides comments'
assert_contains "$out" 'logs=en_US' 'case 4: inline default provides logs'
assert_contains "$out" 'test-logs=en_US' 'case 4: inline default provides test-logs'

# Case 5: no arguments at all -> inline default, exit 0.
out=$(sh "$RESOLVER") && rc=0 || rc=$?
assert_contains "$out" 'issues=en_US' 'case 5: no args yields inline default'
if [ "$rc" -eq 0 ]; then
    printf 'PASS: case 5: exit 0 with no args\n'
else
    printf 'FAIL: case 5: exit status %s\n' "$rc"; failures=$((failures + 1))
fi

# Case 6: each repository scope must override the scopes below it. A
# wrong candidate order changes the distinctive locale in this output.
repo="$root/repo"
mkdir -p "$repo/.rules-for-ai" "$root/config/rules-for-ai"
git -C "$repo" init --quiet
cat > "$root/config/rules-for-ai/LOCALE.md" <<'EOF'
issues=user_USER
pull-requests=user_USER
comments=user_USER
logs=user_USER
test-logs=user_USER
EOF
cat > "$repo/.rules-for-ai/LOCALE.md" <<'EOF'
issues=project_PROJECT
pull-requests=project_PROJECT
comments=project_PROJECT
logs=project_PROJECT
test-logs=project_PROJECT
EOF
git_dir=$(git -C "$repo" rev-parse --absolute-git-dir)
mkdir -p "$git_dir/rules-for-ai"
cat > "$git_dir/rules-for-ai/LOCALE.md" <<'EOF'
issues=local_LOCAL
pull-requests=local_LOCAL
comments=local_LOCAL
logs=local_LOCAL
test-logs=local_LOCAL
EOF
out=$(sh "$SCOPED_RESOLVER" "$repo" \
    "$root/config/rules-for-ai/LOCALE.md" "$REPO/LOCALE.default.md")
assert_contains "$out" 'issues=local_LOCAL' 'case 6: local scope wins'
rm "$git_dir/rules-for-ai/LOCALE.md"
out=$(sh "$SCOPED_RESOLVER" "$repo" \
    "$root/config/rules-for-ai/LOCALE.md" "$REPO/LOCALE.default.md")
assert_contains "$out" 'issues=project_PROJECT' 'case 6: project scope wins without local'
rm "$repo/.rules-for-ai/LOCALE.md"
out=$(sh "$SCOPED_RESOLVER" "$repo" \
    "$root/config/rules-for-ai/LOCALE.md" "$REPO/LOCALE.default.md")
assert_contains "$out" 'issues=user_USER' 'case 6: user scope wins without repository files'

# Case 7: Git metadata keeps a local file out of worktree status. This
# prevents an accidental commit without an exclude-file mutation.
cat > "$git_dir/rules-for-ai/LOCALE.md" <<'EOF'
issues=local_LOCAL
pull-requests=local_LOCAL
comments=local_LOCAL
logs=local_LOCAL
test-logs=local_LOCAL
EOF
status=$(git -C "$repo" status --short)
if [ -z "$status" ]; then
    printf 'PASS: case 7: local scope stays out of git status\n'
else
    printf 'FAIL: case 7: local scope changed git status (%s)\n' "$status"
    failures=$((failures + 1))
fi

# Case 8: linked worktrees need separate local files. A common Git
# directory leaks one developer preference into both trees.
git -C "$repo" -c user.email=test@test.invalid -c user.name=test \
    commit --quiet --allow-empty -m fixture
linked="$root/linked"
git -C "$repo" worktree add --quiet -b linked "$linked"
linked_git_dir=$(git -C "$linked" rev-parse --absolute-git-dir)
mkdir -p "$linked_git_dir/rules-for-ai"
cat > "$linked_git_dir/rules-for-ai/LOCALE.md" <<'EOF'
issues=linked_LINKED
pull-requests=linked_LINKED
comments=linked_LINKED
logs=linked_LINKED
test-logs=linked_LINKED
EOF
out=$(sh "$SCOPED_RESOLVER" "$repo" \
    "$root/config/rules-for-ai/LOCALE.md" "$REPO/LOCALE.default.md")
assert_contains "$out" 'issues=local_LOCAL' 'case 8: primary worktree keeps its local scope'
out=$(sh "$SCOPED_RESOLVER" "$linked" \
    "$root/config/rules-for-ai/LOCALE.md" "$REPO/LOCALE.default.md")
assert_contains "$out" 'issues=linked_LINKED' 'case 8: linked worktree gets its local scope'

rm -rf "$root"

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
