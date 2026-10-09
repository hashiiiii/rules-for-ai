# Upstream source

- Repository: https://github.com/coji/natural-japanese
- Commit: `9a78a42964096da509b8f3e011f0085a5f080151`
- Source directory: `skills/natural-japanese/`
- License: [MIT](LICENSE)

`SKILL.md` is copied as `INSTRUCTIONS.md` so the bundle exposes only `hashiiiii-write-ja`.
References to upstream `SKILL.md` mean `INSTRUCTIONS.md` in this directory.
The references, assets, and runtime scripts are copied from that revision.
Trailing blank lines in `memo.md`, `lint.py`, `outline.py`, and `terms.py` are removed for Git whitespace checks.
Their other content is unchanged.
The development script `calibrate.py` is omitted because it requires the upstream repository's corpus.

To update, select an upstream commit and replace the copied files from that revision.
Keep the instruction filename, license, and wrapper constraints. Update the commit above and run the installation and writing checks.
