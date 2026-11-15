# Upstream source

- Repository: https://github.com/nanaism/yomiyasu
- Commit: `db78b9bc5e868549b517a037df7a4d1c93edac23`
- Source directory: `skills/yomiyasu/`
- License: [MIT](LICENSE)
- Unicode data license: [Unicode License V3](UNICODE-LICENSE.txt)

`SKILL.md` is copied as `INSTRUCTIONS.md` so the bundle exposes only `hashiiiii-write-ja`.
References to upstream `SKILL.md` mean `INSTRUCTIONS.md` in this directory.
The scripts, references, assets, and licenses are copied from that revision.
In `scripts/yomiyasu_check.py`, the instruction fingerprint reads `INSTRUCTIONS.md` instead of `SKILL.md`.
All other upstream content is unchanged.

To update, replace the bundle from a selected upstream commit and repeat the filename adaptation.
Update the commit above, then run the installation tests and a real draft through `run` and `verify`.
