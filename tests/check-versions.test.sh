#!/bin/sh
set -u

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
failures=0
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

mkdir -p "$root/scripts" "$root/.claude-plugin" "$root/.codex-plugin" "$root/.cursor-plugin"
cp "$REPO/scripts/check-versions.sh" "$root/scripts/check-versions.sh"
cp "$REPO/.bumpversion.toml" "$root/.bumpversion.toml"
cp "$REPO/.claude-plugin/plugin.json" "$root/.claude-plugin/plugin.json"
cp "$REPO/.codex-plugin/plugin.json" "$root/.codex-plugin/plugin.json"
cp "$REPO/.cursor-plugin/plugin.json" "$root/.cursor-plugin/plugin.json"

out=$(cd "$root" && sh scripts/check-versions.sh 2>&1)
status=$?
if [ "$status" -eq 0 ]; then
    printf 'PASS: matching version files pass\n'
else
    printf 'FAIL: matching version files failed: %s\n' "$out"
    failures=$((failures + 1))
fi

version=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$root/.claude-plugin/plugin.json" | head -n 1)
sed 's/^current_version = ".*"/current_version = "9.9.9"/' \
    "$root/.bumpversion.toml" > "$root/.bumpversion.toml.new"
mv "$root/.bumpversion.toml.new" "$root/.bumpversion.toml"

out=$(cd "$root" && sh scripts/check-versions.sh 2>&1)
status=$?
if [ "$status" -ne 0 ]; then
    printf 'PASS: bump version mismatch fails\n'
else
    printf 'FAIL: bump version mismatch passed\n'
    failures=$((failures + 1))
fi

case "$out" in
    *"claude=$version codex=$version cursor=$version bump=9.9.9"*)
        printf 'PASS: mismatch output shows all version values\n'
        ;;
    *)
        printf 'FAIL: mismatch output omitted a version value: %s\n' "$out"
        failures=$((failures + 1))
        ;;
esac

if [ "$failures" -gt 0 ]; then
    printf '%s test(s) failed\n' "$failures"
    exit 1
fi
printf 'all tests passed\n'
