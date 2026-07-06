#!/bin/sh
# Verify the two plugin manifests carry the same version (lockstep).
# Optional: scripts/check-versions.sh vX.Y.Z — also verify tag matches.
set -eu

# Minimal JSON "version" extraction; the manifests are flat objects we
# own, so a sed pull of the first "version" value is sufficient.
extract_version() {
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n 1
}

claude=$(extract_version .claude-plugin/plugin.json)
cursor=$(extract_version .cursor-plugin/plugin.json)

if [ -z "$claude" ] || [ "$claude" != "$cursor" ]; then
    printf 'version mismatch: claude=%s cursor=%s\n' "$claude" "$cursor" >&2
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
