#!/bin/sh
# Bundled resources must survive installation without exposing another skill name.
# Temporary repositories keep these checks out of the user's configuration.
set -eu

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

for platform in codex cursor; do
    target="$scratch/$platform"
    git init -q "$target"
    sh "$REPO/rules-for-ai.sh" install "$platform" project "$target" > /dev/null
    case "$platform" in
        codex) skills="$target/.agents/skills" ;;
        cursor) skills="$target/.cursor/skills" ;;
    esac

    for bundle in 'ja natural-japanese' 'en humanizer'; do
        language=${bundle%% *}
        upstream=${bundle#* }
        skill="$skills/hashiiiii-write-$language"
        vendor="$skill/vendor/$upstream"
        for resource in INSTRUCTIONS.md LICENSE UPSTREAM.md; do
            if [ ! -f "$vendor/$resource" ]; then
                printf 'FAIL: %s %s bundle is missing %s\n' "$platform" "$language" "$resource" >&2
                exit 1
            fi
        done
        diff -r "$REPO/skills/hashiiiii-write-$language" "$skill"
        # Nested manifests can publish upstream skills alongside the stable entrypoint.
        manifests=$(find "$skill" -iname SKILL.md | wc -l | tr -d ' ')
        if [ "$manifests" -ne 1 ]; then
            printf 'FAIL: %s %s publishes %s skill manifests\n' "$platform" "$language" "$manifests" >&2
            exit 1
        fi
        printf 'PASS: %s installs the complete %s bundle with one entrypoint\n' "$platform" "$language"
    done
done
printf 'all tests passed\n'
