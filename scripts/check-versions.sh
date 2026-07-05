#!/bin/sh
# Verify the three plugin manifests carry the same version (lockstep).
set -eu

# Minimal JSON "version" extraction; the manifests are flat objects we
# own, so a sed pull of the first "version" value is sufficient.
extract_version() {
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n 1
}

claude=$(extract_version .claude-plugin/plugin.json)
codex=$(extract_version .codex-plugin/plugin.json)
cursor=$(extract_version .cursor-plugin/plugin.json)

if [ -z "$claude" ] || [ "$claude" != "$codex" ] || [ "$claude" != "$cursor" ]; then
    printf 'version mismatch: claude=%s codex=%s cursor=%s\n' "$claude" "$codex" "$cursor" >&2
    exit 1
fi
printf 'versions in lockstep: %s\n' "$claude"
