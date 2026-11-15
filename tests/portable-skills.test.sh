#!/bin/sh
# Migrated skills must keep their names and all source resources after installation.
set -eu
REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

for platform in codex cursor; do
    target="$scratch/$platform project"
    git init -q "$target"
    sh "$REPO/rules-for-ai.sh" install "$platform" project "$target" > /dev/null
    case "$platform" in
        codex) skills="$target/.agents/skills" ;;
        cursor) skills="$target/.cursor/skills" ;;
    esac
    for name in hallmark show-me; do
        skill="$skills/$name"
        [ -f "$skill/SKILL.md" ] || fail "missing $name entrypoint"
        for resource in INSTRUCTIONS.md LICENSE UPSTREAM.md; do
            [ -f "$skill/vendor/$name/$resource" ] || fail "missing $name resource: $resource"
        done
        # A second manifest would expose the bundled skill alongside the stable public name.
        manifests=$(find "$skill" -iname SKILL.md | wc -l | tr -d ' ')
        [ "$manifests" -eq 1 ] || fail "$name publishes multiple entrypoints"
        diff -r "$REPO/skills/$name" "$skill"
        # Renaming upstream instructions must not break navigation between bundled references.
        python3 - "$skill" <<'PY'
from pathlib import Path
import re
import sys
from urllib.parse import unquote

for document in Path(sys.argv[1]).rglob('*.md'):
    for target in re.findall(r'\[[^\n]*?\]\(([^\s)]+)\)', document.read_text()):
        if re.match(r'^[a-zA-Z][\w+.-]*:', target) or target.startswith('#'):
            continue
        relative = unquote(target.split('#', 1)[0])
        if relative and not (document.parent / relative).exists():
            raise SystemExit(f'FAIL: broken bundled link: {document}: {target}')
PY
        printf 'PASS: %s installs the complete %s skill with one entrypoint\n' "$platform" "$name"
    done
done
printf 'all tests passed\n'
