# Dependency maintenance

Renovate updates GitHub Actions, tools in `mise.toml`, and bundled skills declared in `upstreams.json`.
Updates require seven days of release age and a release timestamp. Automerge is disabled.
The updater runs each Monday at 06:00 JST and can also run through the **dependency updates** workflow's manual trigger.

## Bundled skills

`upstreams.json` pins each release tag and its commit digest, copied paths, destination, and ordered patch list.
The checked-in bundles are generated output. Users install these files without fetching upstream repositories.

To regenerate or verify all bundles, run these commands from the repository root:

```sh
python3 scripts/sync-upstreams.py
python3 scripts/sync-upstreams.py --check
```

Both commands require Git, network access to the upstream repositories, and Python 3.9 or later.
The generator fetches each release tag and verifies its commit before copying files.
It applies patches in staging, renames `SKILL.md` to `INSTRUCTIONS.md`, and generates `UPSTREAM.md`.
All bundles are prepared before any existing bundle is replaced. Failed fetches, commit mismatches, or incompatible patches leave existing output unchanged.
`--check` reports differences without changing files.

Add local adaptations under `patches/<name>/` and list them in `upstreams.json`.
Patches apply to the selected upstream files before the instruction filename is changed.
Do not edit generated files directly. Keep wrapper-specific scope and output rules in the public `SKILL.md`.

Renovate updates the release tag and digest, then runs the generator before committing the dependency PR.
The PR includes generated bundle changes. CI verifies reproducibility, installation, and runtime checks.
When an upstream change breaks a patch, update that patch and regenerate before merging.
For manual updates, change the tag and commit together, regenerate, then run the same checks.

## Updater credentials

The self-hosted Renovate workflow reuses the release workflow's `APP_CLIENT_ID` and `APP_PRIVATE_KEY` secrets.
The App needs repository Contents and Pull requests write permissions, plus Workflows write permission to update Actions references.
Renovate installs Python 3.9 or later before regenerating bundles.
Repository configuration permits one post-upgrade command: `python3 scripts/sync-upstreams.py`.
No dependency updater runs on untrusted pull-request events.

The workflow starts after merging its definition into the default branch.
Its first manual or scheduled run verifies App permissions and live PR creation.
Do not also enable hosted Renovate or Dependabot for the same dependencies.

## Environment tools

CI installs the pinned Node.js, ShellCheck, Claude Code, and Codex versions from `mise.toml`.
The release workflow also uses the pinned `bump-my-version` tool.
Git, Python 3, and GitHub CLI come from the runner environment.
The image skill requires `rsvg-convert` on the machine performing image work; it is not bundled or installed by this repository.
