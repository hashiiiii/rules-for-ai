#!/bin/sh
# Real Git remotes exercise fetching and patch failures without replacing Git commands.
set -eu
REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

git_q() { git -c user.name=Test -c user.email=test@example.invalid "$@"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
sync_bundles() { sh "$REPO/scripts/sync-upstreams.sh" --root "$project" "$@"; }
set_manifest() {
    jq "$@" "$project/upstreams.json" > "$scratch/manifest.json"
    mv "$scratch/manifest.json" "$project/upstreams.json"
}

remote="$scratch/remote with spaces"
project="$scratch/project with spaces"
destination="$project/skills/writing/vendor/upstream"
mkdir -p "$remote/bundle" "$project/patches"
git_q -C "$remote" init -q
printf '%s\n' '---' 'name: upstream' '---' '# Writing' > "$remote/bundle/SKILL.md"
printf '%s\n' 'Test license' > "$remote/bundle/LICENSE"
printf '%s\n' 'Original guidance.' > "$remote/bundle/guide.txt"
# An unrelated upstream development link must not affect the selected bundle.
ln -s bundle "$remote/development-link"
git_q -C "$remote" add .
git_q -C "$remote" commit -qm 'initial source'
git_q -C "$remote" tag v1.0.0
revision=$(git -C "$remote" rev-parse HEAD)
jq -n --arg repository "file://$remote" --arg revision "$revision" '{bundles: [{
    name: "upstream", repository: $repository, version: "v1.0.0", revision: $revision,
    source: "bundle", destination: "skills/writing/vendor/upstream",
    include: ["."], patches: ["patches/upstream.patch"]
}]}' > "$project/upstreams.json"
cat > "$project/patches/upstream.patch" <<'EOF'
diff --git a/guide.txt b/guide.txt
--- a/guide.txt
+++ b/guide.txt
@@ -1 +1 @@
-Original guidance.
+Local guidance.
EOF

# The generated copy must retain resources without publishing another skill name.
sync_bundles > /dev/null
[ "$(cat "$destination/guide.txt")" = 'Local guidance.' ] || fail 'patch is not applied'
[ -f "$destination/INSTRUCTIONS.md" ] || fail 'instructions are missing'
[ ! -e "$destination/SKILL.md" ] || fail 'nested skill manifest is exposed'
grep -q "$revision" "$destination/UPSTREAM.md" || fail 'source commit is missing'
sync_bundles --check > /dev/null

# Executable bits affect how installed resources can be invoked.
chmod u+x "$destination/INSTRUCTIONS.md"
if sync_bundles --check > /dev/null; then fail 'executable-bit drift is ignored'; fi
chmod u-x "$destination/INSTRUCTIONS.md"
printf '%s\n' 'Changed output.' > "$destination/guide.txt"
if sync_bundles --check > /dev/null; then fail 'content drift is ignored'; fi
[ "$(cat "$destination/guide.txt")" = 'Changed output.' ] || fail 'check modifies output'
sync_bundles > /dev/null
sync_bundles --check > /dev/null
printf 'PASS: generation preserves resources and detects content and executable-bit drift\n'

# Single-file workflows must not copy unrelated upstream development files.
set_manifest '.bundles[0].include = ["SKILL.md", "LICENSE"] | .bundles[0].patches = []'
sync_bundles > /dev/null
[ -f "$destination/LICENSE" ] || fail 'selected license is missing'
[ ! -e "$destination/guide.txt" ] || fail 'unselected file is copied'
set_manifest '.bundles[0].include = ["."] | .bundles[0].patches = ["patches/upstream.patch"]'
sync_bundles > /dev/null
printf 'PASS: copy selection omits unrelated files\n'

# A failed later bundle must preserve a pending update to the earlier bundle.
cp "$destination/UPSTREAM.md" "$scratch/provenance.md"
printf '%s\n' 'Not a patch.' > "$project/patches/broken.patch"
cp "$project/upstreams.json" "$scratch/valid.json"
set_manifest '.bundles += [(.bundles[0] | .name = "other" | .destination = "skills/writing/vendor/other" | .patches = ["patches/broken.patch"])] | .bundles[0].patches = []'
if sync_bundles > "$scratch/output" 2>&1; then fail 'invalid patch is accepted'; fi
[ "$(cat "$destination/guide.txt")" = 'Local guidance.' ] || fail 'earlier bundle is replaced on failure'
cmp "$destination/UPSTREAM.md" "$scratch/provenance.md"
[ ! -e "$project/skills/writing/vendor/other" ] || fail 'failed bundle is published'
cp "$scratch/valid.json" "$project/upstreams.json"
printf 'PASS: patch failures preserve every bundle\n'

# A manifest mistake must not replace another part of the repository.
set_manifest '.bundles[0].destination = "../outside"'
if sync_bundles > "$scratch/output" 2>&1; then fail 'invalid destination is accepted'; fi
grep -q 'destination' "$scratch/output" || fail 'invalid destination lacks a useful error'
cp "$scratch/valid.json" "$project/upstreams.json"
printf 'PASS: output remains in vendor directories\n'

# Selected source paths must not follow a development link, even through a parent component.
set_manifest '.bundles[0].source = "development-link"'
if sync_bundles > "$scratch/output" 2>&1; then fail 'selected symlink is followed'; fi
grep -q 'symlink' "$scratch/output" || fail 'selected symlink lacks a useful error'
[ "$(cat "$destination/guide.txt")" = 'Local guidance.' ] || fail 'selected symlink replaces output'
cp "$scratch/valid.json" "$project/upstreams.json"
printf 'PASS: selected symlinks are rejected without blocking unrelated links\n'

# A moved tag must not override the reviewed commit pin.
printf '%s\n' 'Moved release.' > "$remote/bundle/guide.txt"
git_q -C "$remote" add .
git_q -C "$remote" commit -qm 'move release'
git_q -C "$remote" tag -f v1.0.0 > /dev/null
if sync_bundles > "$scratch/output" 2>&1; then fail 'moved release tag is accepted'; fi
grep -q 'commit mismatch' "$scratch/output" || fail 'commit mismatch lacks a useful error'
[ "$(cat "$destination/guide.txt")" = 'Local guidance.' ] || fail 'moved tag replaces output'
printf 'PASS: moved tags preserve reviewed output\n'
printf 'all tests passed\n'
