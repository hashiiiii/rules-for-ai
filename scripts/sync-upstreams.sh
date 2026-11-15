#!/bin/sh
# Stage every source and patch before replacing any checked-in bundle.
set -eu

root="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
check=0
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root) [ "$#" -ge 2 ] || die '--root requires a directory'; root=$2; shift 2 ;;
        --check) check=1; shift ;;
        *) die "usage: $0 [--root directory] [--check]" ;;
    esac
done
for tool in git jq; do
    command -v "$tool" > /dev/null 2>&1 || die "$tool is required"
done
root=$(CDPATH='' cd -- "$root" && pwd -P)
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
manifest="$root/upstreams.json"

# Line-oriented shell loops require paths and metadata without control characters.
jq -e '
    def text: type == "string" and (test("[\u0000-\u001f\u007f]") | not);
    def relative: text and length > 0 and (startswith("/") | not)
        and (contains("\\") | not) and (split("/") | all(. != ".." and . != ".git"));
    .bundles | type == "array" and length > 0 and
    all(.[];
        (.name | text and length > 0) and
        (.repository | text and length > 0) and
        (.version | text and test("^v?[0-9]+\\.[0-9]+\\.[0-9]+$")) and
        (.revision | text and test("^[0-9a-f]{40}$")) and
        (.source | relative) and
        (.destination | text and test("^skills/[A-Za-z0-9][A-Za-z0-9._-]*/vendor/[A-Za-z0-9][A-Za-z0-9._-]*$")) and
        (.include | type == "array" and length > 0 and all(.[]; relative)) and
        (.patches | type == "array" and all(.[]; relative))) and
    (map(.destination) | length == (unique | length))
' "$manifest" > /dev/null || die 'invalid upstream manifest, paths, or duplicate destination'
jq -c '.bundles[]' "$manifest" > "$stage/entries"
: > "$stage/changed"
number=0
while IFS= read -r bundle; do
    work="$stage/$number"
    mkdir -p "$work/checkout" "$work/source" "$work/output"
    printf '%s\n' "$bundle" > "$work/entry.json"
    repository=$(jq -r '.repository' "$work/entry.json")
    version=$(jq -r '.version' "$work/entry.json")
    revision=$(jq -r '.revision' "$work/entry.json")
    source=$(jq -r '.source' "$work/entry.json")
    destination=$(jq -r '.destination' "$work/entry.json")
    skill=${destination#skills/}; skill=${skill%%/*}
    # A generated destination must not redirect replacement through a symlink.
    for path in "$root/skills" "$root/skills/$skill" "$root/skills/$skill/vendor" "$root/$destination"; do
        [ ! -L "$path" ] || die "symlink in destination: $destination"
    done
    printf '%s\n' "$destination" > "$work/destination"
    git -C "$work/checkout" init -q
    git -C "$work/checkout" fetch -q --depth=1 --no-tags -- "$repository" "refs/tags/$version"
    actual=$(git -C "$work/checkout" rev-parse 'FETCH_HEAD^{commit}')
    [ "$actual" = "$revision" ] || die "commit mismatch for $repository: expected $revision, got $actual"
    # An archive excludes Git metadata even when the selected source is the repository root.
    git -C "$work/checkout" -c tar.umask=0022 archive FETCH_HEAD > "$work/source.tar"
    tar -xf "$work/source.tar" -C "$work/source"
    jq -r '.include[]' "$work/entry.json" > "$work/include"
    while IFS= read -r path; do
        item="$work/source/$source/$path"
        copied="$work/output/$path"
        [ -e "$item" ] || die "missing upstream resource: $path"
        # Only selected resources matter, but their parent paths must not redirect copying.
        checked=$item
        while [ "$checked" != "$work/source" ]; do
            [ ! -L "$checked" ] || die "symlink in selected resource: $path"
            checked=$(dirname -- "$checked")
        done
        [ -z "$(find "$item" -type l -print -quit)" ] || die "symlink in selected resource: $path"
        if [ -d "$item" ]; then
            mkdir -p "$copied"
            cp -pR "$item/." "$copied/"
        else
            mkdir -p "$(dirname -- "$copied")"
            cp -p "$item" "$copied"
        fi
    done < "$work/include"
    jq -r '.patches[]' "$work/entry.json" > "$work/patches"
    while IFS= read -r patch; do
        git -C "$work/output" apply --check "$root/$patch"
        git -C "$work/output" apply "$root/$patch"
    done < "$work/patches"
    mv "$work/output/SKILL.md" "$work/output/INSTRUCTIONS.md"
    [ -z "$(find "$work/output" -iname SKILL.md -print -quit)" ] || die "nested skill manifest in $destination"
    # Backticks in the generated Markdown must remain literal.
    # shellcheck disable=SC2016
    {
        printf '# Upstream source\n\n- Repository: %s\n- Release: `%s`\n- Commit: `%s`\n- Source directory: `%s`\n' \
            "$repository" "$version" "$revision" "$source"
        printf -- '- Included paths: %s\n\n' "$(jq -r '.include | map("`" + . + "`") | join(", ")' "$work/entry.json")"
        printf '%s\n' \
            '`SKILL.md` is renamed to `INSTRUCTIONS.md` to expose only the wrapper'"'"'s skill name.' \
            'Upstream licenses are retained in this directory.' '' '## Local patches' ''
        if [ -s "$work/patches" ]; then
            while IFS= read -r patch; do printf -- '- `%s`\n' "$patch"; done < "$work/patches"
        else
            printf 'None.\n'
        fi
        printf '\n%s\n%s\n' \
            'Update `upstreams.json`, then run `sh scripts/sync-upstreams.sh` from the repository root.' \
            'This file is generated. Do not edit the bundle directly.'
    } > "$work/output/UPSTREAM.md"
    if [ -d "$root/$destination" ]; then
        if git -c core.fileMode=true diff --no-index --no-ext-diff --quiet -- "$root/$destination" "$work/output"; then
            number=$((number + 1))
            continue
        else
            status=$?
            [ "$status" -eq 1 ] || die "could not compare bundle: $destination"
        fi
    fi
    printf '%s\n' "$number" >> "$stage/changed"
    number=$((number + 1))
done < "$stage/entries"

while IFS= read -r number; do
    destination=$(cat "$stage/$number/destination")
    if [ "$check" -eq 1 ]; then
        printf 'DRIFT: %s\n' "$destination"
    else
        printf 'UPDATE: %s\n' "$destination"
        rm -rf "${root:?}/${destination:?}"
        mkdir -p "$root/$destination"
        cp -pR "$stage/$number/output/." "$root/$destination/"
    fi
done < "$stage/changed"
if [ ! -s "$stage/changed" ]; then
    printf 'Bundled skills match the pinned upstream sources and patches.\n'
elif [ "$check" -eq 1 ]; then
    exit 1
fi
