# Dependency maintenance

Renovate updates GitHub Actions, tools in `mise.toml`, bundled skills in `upstreams.json`, and the English checker's npm manifests.
Updates require seven days of release age and a release timestamp. Automerge is disabled.
The updater runs each Monday at 06:00 JST and can also run through the **dependency updates** workflow's manual trigger.

## Bundled skills

`upstreams.json` pins each source's commit, copied paths, destination, and ordered patch list.
Tagged sources use `version`; tagless sources use a tracked `ref` and immutable `revision`.
Optional `resources` entries map selected repository-root files into the bundle, including licenses and Hallmark's palette tokens.
The checked-in bundles are generated output. Users install these files without fetching upstream repositories.

To regenerate or verify all bundles, run these commands from the repository root:

```sh
sh scripts/sync-upstreams.sh
sh scripts/sync-upstreams.sh --check
```

Both commands require a POSIX shell, Git, jq, and network access to the upstream repositories.
The generator fetches a release tag and verifies its commit, or fetches the exact pinned SHA for a tracked ref.
Movement of a tracked branch does not change a generated bundle.
It applies patches in staging, renames `SKILL.md` to `INSTRUCTIONS.md`, and generates `UPSTREAM.md`.
All bundles are prepared before any existing bundle is replaced. Failed fetches, commit mismatches, or incompatible patches leave existing output unchanged.
`--check` reports differences without changing files.
An unregistered directory under `skills/*/vendor/` fails validation, so a new bundled source cannot silently escape update management.

Add local adaptations under `patches/<name>/` and list them in `upstreams.json`.
Patches apply to the selected upstream files before the instruction filename is changed.
Do not edit generated files directly. Keep wrapper-specific scope and output rules in the public `SKILL.md`.

Renovate updates the release tag and digest, then runs the generator before committing the dependency PR.
For tagless sources, its `github-digest` datasource updates the commit and supplies commit timestamps for the same seven-day age check.
An active branch may remain ineligible until its current head is old enough; no timestamp exception is enabled.
The PR includes generated bundle changes. CI verifies reproducibility, installation, and runtime checks.
When an upstream change breaks a patch, update that patch and regenerate before merging.
For manual tagged updates, change the tag and commit together. For tracked refs, change the commit.
Regenerate, then run the same checks.

## Updater credentials

The self-hosted Renovate workflow reuses the release workflow's `APP_CLIENT_ID` and `APP_PRIVATE_KEY` secrets.
The App needs repository Contents and Pull requests write permissions, plus Workflows write permission to update Actions references.
Repository configuration permits one post-upgrade command: `sh scripts/sync-upstreams.sh`.
The dependency workflow uses `actions/github-script` to resolve the bot identity.
No dependency updater runs on untrusted pull-request events.

The workflow starts after merging its definition into the default branch.
Its first manual or scheduled run verifies App permissions and live PR creation.
Do not also enable hosted Renovate or Dependabot for the same dependencies.

## Environment tools

CI installs the pinned Node.js, ShellCheck, jq, Claude Code, and Codex versions from `mise.toml`.
The release workflow also uses the pinned `bump-my-version` tool.
Git and GitHub CLI come from the runner environment.
The upstream yomiyasu checks use Python 3. Custom maintenance scripts and tests use shell.
The English checker uses Node.js 20 or later and its own locked `harper.js` and `fflate` packages.
Setup requires npm and downloads packages to a shared user cache; subsequent checks run offline.
Its [runtime documentation](../skills/hashiiiii-write-en/DEPENDENCIES.md) covers cache paths, commands, licenses, and candidate selection.
The image skill requires `rsvg-convert` on the machine performing image work; it is not bundled or installed by this repository.

## Skill audit

The November 15, 2026 audit read the original nine public skills and their bundled resources, plus the personal skill installations in dotfiles and the user's skill directory.
Hallmark and Show-me now belong to this plugin, preserving their public names.
Reference links to documentation are distinguished from copied source and executable dependencies.

| Public skill | Source or runtime dependency | Update owner |
| --- | --- | --- |
| `hashiiiii-write-ja` | yomiyasu; Python 3 standard library | `upstreams.json` and the host's Python installation |
| `hashiiiii-write-en` | Harper and `fflate`; Node.js and npm | Skill npm manifests and lockfile; `mise.toml` in CI |
| `hashiiiii-images` | `rsvg-convert` from librsvg; a raster generator when the task needs one | Host package manager; the selected agent's image tool |
| `hashiiiii-git` | Git | Host or CI runner |
| `hashiiiii-issues` | GitHub access; `gh` in its shell example | Connected GitHub tools or host GitHub CLI |
| `hashiiiii-pull-request` | Git, GitHub access; `gh` in its shell example | Connected GitHub tools or host GitHub CLI |
| `hashiiiii-explain-pr` | Repository and GitHub access; relevant official documentation | Agent tools and each reviewed project's dependencies |
| `hashiiiii-locale` | Git for project and worktree paths | Host or CI runner |
| `hashiiiii-zig` | The target project's Zig toolchain; linked language and testing references | Target project; no copied external source |
| `hallmark` | Nutlope/hallmark source and required design resources; browser access for previews and URL study | `upstreams.json`; project dependencies and agent browser tools |
| `show-me` | HumanLayer's Show-me instructions; a browser or file opener for HTML artifacts | `upstreams.json`; host or agent tools |

Humanizer was already registered before this audit. It has been removed and replaced by the locked Harper runtime.
The reference links in `hashiiiii-zig` are reading material, so they do not require vendored source pins.
Runtime plugins supplied by Codex, Claude Code, or Cursor remain under their respective plugin managers; their installed caches are generated state.

Hallmark's recommended fonts, image services, and UI libraries are conditional design inputs, not packages installed by this plugin.
When selected for a project, that project owns their installation and versioning. Hallmark's text-only and local SVG alternatives need no image-service account.

## Ownership and other installations

Portable instructions, bundled source, provenance, patches, and dependency checks belong in rules-for-ai.
Dotfiles owns plugin enabling, machine settings, and OS packages. The migrated skill implementations are no longer copied into dotfiles.
On this macOS installation, librsvg is explicitly declared in the dotfiles Brewfile; it supplies the image skill's `rsvg-convert` command.

The audit also inspected skills installed separately through the Skills CLI:

| Installation | Recorded owner and source | Maintenance |
| --- | --- | --- |
| `find-skills` | `vercel-labs/skills`; installed folder hash in `~/.agents/.skill-lock.json` | Skills CLI manages the installation; it is not a bundled plugin dependency. |
| `grill-me` and `grilling` | `mattpocock/skills`; installed folder hashes in the same lock | Skills CLI manages both the entrypoint and its required interview skill. |

The inspected `find-skills` copy matches commit `ceea0088e483744887186fb911841bf5449b8324` with a local source-link edit.
The inspected `grill-me` instructions match commit `cbf6db4233c7e4202abaf79643f7ab395c75a2df`.
Its missing `grilling` dependency was installed from that same commit for Codex and Claude Code, through Skills CLI 1.7.6.
The CLI version is now pinned in dotfiles' global mise configuration; it was published on November 3, more than seven days before this audit.
The local `find-skills` guidance now uses that managed CLI and omits its unsupported `check` command, while retaining the existing source-link edit.
These observations describe that machine's audit snapshot, not files distributed by this repository.
Review local edits before updating those installations through their package manager; their installed files are not regenerated by `sync-upstreams.sh`.
Broken legacy `simple-english` and `stop-ai-slop-jp` links to removed dotfiles paths were removed; they had no source files to register.
