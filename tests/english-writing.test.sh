#!/bin/sh
# Real grammar checks catch broken packaging and API changes without substituting the engine.
set -eu
REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
checker="$REPO/skills/hashiiiii-write-en/scripts/check.mjs"
export XDG_CACHE_HOME="$scratch/cache with spaces"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# A missing runtime must explain setup instead of reporting an unchecked draft as clean.
printf '%s\n' 'This is a example.' > "$scratch/draft.md"
if node "$checker" "$scratch/draft.md" > "$scratch/result.json" 2> "$scratch/error"; then
    fail 'missing dependency is reported as success'
fi
grep -q 'setup' "$scratch/error" || fail 'missing dependency lacks setup instructions'
node "$checker" setup > /dev/null

# The checker must load its pinned runtime outside both the project and the skill directory.
cp "$scratch/draft.md" "$scratch/original.md"
(cd "$scratch" && node "$checker" "$scratch/draft.md" > "$scratch/result.json")
jq -e 'any(.diagnostics[]; .problem == "a" and (.suggestions | any(.text == "an")))' \
    "$scratch/result.json" > /dev/null || fail 'article error is not detected'
cmp "$scratch/draft.md" "$scratch/original.md"
printf 'PASS: pinned grammar checks report suggestions without editing the source\n'

# Code and link targets contain identifiers that must not be treated as editable prose.
cat > "$scratch/technical.md" <<'EOF'
The server stores the result.

`This is a example.`

```text
This is a example.
```

See [the guide](https://example.com/this-is-a-example).
EOF
node "$checker" "$scratch/technical.md" > "$scratch/result.json"
jq -e '.diagnostics | length == 0' "$scratch/result.json" > /dev/null || fail 'Markdown code or link target is checked'

# Code-point offsets must still identify the right word after a supplementary Unicode character.
cat > "$scratch/unicode.md" <<'EOF'
`𠮷`

This is a example.
EOF
node "$checker" "$scratch/unicode.md" > "$scratch/result.json"
jq -e 'any(.diagnostics[]; .problem == "a" and .line == 3 and .column == 9)' \
    "$scratch/result.json" > /dev/null || fail 'Unicode corrupts diagnostic positions'
printf 'PASS: Markdown exclusions and Unicode positions survive integration\n'

# Reports identify the exact bytes checked so a later edit cannot reuse an earlier result.
before=$(jq -r '.sha256' "$scratch/result.json")
printf '%s\n' 'The server stores the result.' > "$scratch/unicode.md"
node "$checker" "$scratch/unicode.md" > "$scratch/result.json"
[ "$before" != "$(jq -r '.sha256' "$scratch/result.json")" ] || fail 'report ignores changed draft'
jq -e '.diagnostics | length == 0' "$scratch/result.json" > /dev/null || fail 'clean prose is reported as incorrect'
if node "$checker" "$scratch/absent.md" > /dev/null 2> "$scratch/error"; then fail 'missing input is accepted'; fi
if node "$checker" --dialect unknown "$scratch/draft.md" > /dev/null 2> "$scratch/error"; then fail 'invalid dialect is accepted'; fi
printf 'PASS: clean drafts, changed drafts, and invalid inputs are distinguished\n'

# Dialect selection must reach the engine, not just change the report label.
printf '%s\n' 'The colour is blue.' > "$scratch/british.txt"
node "$checker" --dialect British "$scratch/british.txt" > "$scratch/result.json"
jq -e '.diagnostics | length == 0' "$scratch/result.json" > /dev/null || fail 'British spelling is rejected'
node "$checker" "$scratch/british.txt" > "$scratch/result.json"
jq -e 'any(.diagnostics[]; .problem == "colour")' "$scratch/result.json" > /dev/null || fail 'American dialect is not applied'
printf 'PASS: dialect selection controls spelling checks\n'

# Copies installed by each supported file installer must run from their own resource paths.
for platform in codex cursor; do
    target="$scratch/$platform"
    git init -q "$target"
    sh "$REPO/rules-for-ai.sh" install "$platform" project "$target" > /dev/null
    case "$platform" in
        codex) skill="$target/.agents/skills/hashiiiii-write-en" ;;
        cursor) skill="$target/.cursor/skills/hashiiiii-write-en" ;;
    esac
    node "$skill/scripts/check.mjs" "$scratch/draft.md" > "$scratch/result.json"
    jq -e 'any(.diagnostics[]; .problem == "a")' "$scratch/result.json" > /dev/null || fail 'installed checker cannot load its runtime'
    printf 'PASS: %s runs the installed English checker\n' "$platform"
done
printf 'all tests passed\n'
