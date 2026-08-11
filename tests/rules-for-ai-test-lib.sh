#!/bin/sh
REPO=${REPO:?the caller must set REPO}
failures=${failures:-0}

assert_contains() {
    case "$1" in
        *"$2"*) printf 'PASS: %s\n' "$3" ;;
        *) printf 'FAIL: %s (missing: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
    esac
}

assert_not_contains() {
    case "$1" in
        *"$2"*) printf 'FAIL: %s (unexpected: %s)\n' "$3" "$2"; failures=$((failures + 1)) ;;
        *) printf 'PASS: %s\n' "$3" ;;
    esac
}

assert_file() {
    if [ -e "$1" ]; then
        printf 'PASS: %s\n' "$2"
    else
        printf 'FAIL: %s (missing: %s)\n' "$2" "$1"; failures=$((failures + 1))
    fi
}

assert_no_file() {
    if [ -e "$1" ]; then
        printf 'FAIL: %s (still exists: %s)\n' "$2" "$1"; failures=$((failures + 1))
    else
        printf 'PASS: %s\n' "$2"
    fi
}

# This identity permits commits on CI machines that have no global identity.
git_q() { git -c user.email=test@test.invalid -c user.name=test "$@"; }

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
    # This tag proves that the installed hook reads the copied default file.
    printf 'issues=xx_XX\npull-requests=xx_XX\ncomments=xx_XX\nlogs=xx_XX\ntest-logs=xx_XX\n' \
        > "$src/LOCALE.default.md"
    cp "$REPO/rules-for-ai.sh" "$src/rules-for-ai.sh"
    mkdir -p "$src/hooks"
    cp "$REPO/hooks/resolve-locale.sh" "$src/hooks/resolve-locale.sh"
    cp "$REPO/hooks/resolve-scoped-locale.sh" "$src/hooks/resolve-scoped-locale.sh"
    cp "$REPO/hooks/session-start-cursor.sh" "$src/hooks/session-start-cursor.sh"
    cp "$REPO/hooks/json-escape.sh" "$src/hooks/json-escape.sh"
    cp "$REPO/hooks/check-pr-template.sh" "$src/hooks/check-pr-template.sh"
    cp "$REPO/hooks/pr-template-check-cursor.sh" "$src/hooks/pr-template-check-cursor.sh"
    git_q -C "$src" init --quiet
    git_q -C "$src" add -A
    git_q -C "$src" commit --quiet -m fixture
    printf '%s' "$src"
}

new_target_repo() {
    tgt=$(mktemp -d)
    git_q -C "$tgt" init --quiet
    printf '%s' "$tgt"
}
