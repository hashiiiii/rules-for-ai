# Upstream source

- Repository: https://github.com/Nutlope/hallmark
- Tracked ref: `main`
- Commit: `aeb42fb354ff4efa36ab475773a082315a3af2ce`
- Source directory: `skills/hallmark`
- Included paths: `.`

Additional repository resources:

- `LICENSE` -> `LICENSE`
- `site/css/tokens.css` -> `site/css/tokens.css`

`SKILL.md` is renamed to `INSTRUCTIONS.md` to expose only the wrapper's skill name.
Upstream licenses are retained in this directory.

## Local patches

- `patches/hallmark/preserve-local-guidance.patch`
- `patches/hallmark/grid-theme.patch`
- `patches/hallmark/bundled-references.patch`
- `patches/hallmark/catalog-grid.patch`

To review an upstream update, change the pinned release or commit in `upstreams.json`, then run `sh scripts/sync-upstreams.sh` from the repository root.
This file is generated. Do not edit the bundle directly.
