#!/bin/sh
# To compare a tag, run scripts/check-versions.sh vX.Y.Z.
set -eu

# The manifests are flat JSON objects that this repository controls.
# Thus, sed can read the first "version" value without a JSON parser.
extract_version() {
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n 1
}

extract_bump_version() {
    sed -n 's/^current_version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n 1
}

claude=$(extract_version .claude-plugin/plugin.json)
codex=$(extract_version .codex-plugin/plugin.json)
cursor=$(extract_version .cursor-plugin/plugin.json)
bump=$(extract_bump_version .bumpversion.toml)

if [ -z "$claude" ] || [ "$claude" != "$codex" ] || [ "$claude" != "$cursor" ] \
    || [ "$claude" != "$bump" ]; then
    printf 'version mismatch: claude=%s codex=%s cursor=%s bump=%s\n' \
        "$claude" "$codex" "$cursor" "$bump" >&2
    exit 1
fi

if [ $# -gt 0 ]; then
    expected=$1
    actual="v$claude"
    if [ "$actual" != "$expected" ]; then
        printf 'tag %s does not match manifest version %s\n' "$expected" "$claude" >&2
        exit 1
    fi
fi

printf 'versions in lockstep: %s\n' "$claude"
