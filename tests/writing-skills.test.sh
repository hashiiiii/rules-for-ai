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

    for bundle in 'ja yomiyasu' 'en humanizer'; do
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
    # Exercise installed paths because renaming the upstream manifest affects its fingerprint.
    vendor="$skills/hashiiiii-write-ja/vendor/yomiyasu"
    printf '%s\n' '設定を変更する事ができます。' > "$target/source.txt"
    printf '%s\n' '設定を変更できます。' > "$target/final.txt"
    (
        cd "$target"
        python3 "$vendor/scripts/yomiyasu_check.py" run --source "$target/source.txt" \
            --final "$target/final.txt" --state-dir "$target/state" --json > "$target/run.json"
        python3 "$vendor/scripts/yomiyasu_check.py" verify --final "$target/final.txt" \
            --state-dir "$target/state" > /dev/null
    )
    # Upstream reports instruction drift as a finding without changing the exit status.
    printf '\n' >> "$vendor/INSTRUCTIONS.md"
    (cd "$target" && python3 "$vendor/scripts/yomiyasu_check.py" verify \
        --final "$target/final.txt" --state-dir "$target/state" --json > "$target/verify.json")
    if ! grep -q 'skill_changed' "$target/verify.json"; then
        printf 'FAIL: %s ignores changed bundled instructions\n' "$platform" >&2
        exit 1
    fi
    printf 'PASS: %s runs and verifies the installed Japanese bundle\n' "$platform"

done
printf 'all tests passed\n'
