# Rules for AI

Shared rules and skills for Claude Code, Codex, and Cursor.

## Install

Choose a platform (`claude`, `codex`, or `cursor`) and a scope:

| Scope | Use |
| --- | --- |
| `user` | All your projects on this machine |
| `project` | One repository, shared through Git |
| `local` | One repository, with installed files excluded from Git |

For example, install for your Codex user:

```sh
curl -fsSL https://raw.githubusercontent.com/hashiiiii/rules-for-ai/main/rules-for-ai.sh | sh -s -- install codex user
```

From a checkout, use the installer directly:

```sh
./rules-for-ai.sh <install|uninstall> <claude|codex|cursor> <user|project|local> [path/to/repo]
```

The path applies to `project` and `local`; it defaults to the current directory.  
The target must be a Git repository other than this checkout.  
Run the same install command to update. Use `uninstall` with the same platform and scope to remove the installation.

| Platform | Installation |
| --- | --- |
| Claude Code | Requires the `claude` CLI. Uses its plugin manager and scope settings. Teammates must trust the repository to load a project installation. |
| Codex | Copies `AGENTS.md` and skills to `$CODEX_HOME` (default `~/.codex`) and `~/.agents/skills/` for user scope, or to the repository root and `.agents/skills/` for project and local scopes. Restart Codex afterward. |
| Cursor | Uses `~/.cursor/plugins/local/rules-for-ai/` for user scope or `.cursor/` for project and local scopes. Restart Cursor afterward. |

Codex keeps an existing or modified `AGENTS.md` and prints a path for manual merging.  
Codex and Cursor replace bundled skills on installation and remove them on uninstallation, including local edits.  
Cursor keeps a modified or existing foreign `hooks.json` and prints the entries to add or remove manually.  
If Cursor already imports this plugin from Claude Code, skip a second user installation.  
Local scope cannot hide files already tracked by Git; use project scope for those files.

### Codex Native Plugin

To load rules and skills through Codex's plugin system, use:

```sh
codex plugin marketplace add hashiiiii/rules-for-ai
codex plugin add rules-for-ai@hashiiiii
```

Approve the plugin hooks when prompted. Remove it with `codex plugin remove rules-for-ai@hashiiiii`.

## Locale

Use `hashiiiii-locale` with a scope and locale tag, for example `local ja_JP`.  
To set languages separately, use `project issues=ja_JP pull-requests=ja_JP comments=ja_JP logs=en_US test-logs=en_US`.

| Scope | Locale file |
| --- | --- |
| `user` | `$XDG_CONFIG_HOME/rules-for-ai/LOCALE.md` (default `~/.config/rules-for-ai/LOCALE.md`) |
| `project` | `<repo>/.rules-for-ai/LOCALE.md` |
| `local` | `<absolute-git-dir>/rules-for-ai/LOCALE.md` |

Get the local Git directory with `git rev-parse --absolute-git-dir`.  
Locale scope is independent of installation scope.  
Project instructions take precedence; otherwise, the first existing local, project, user, or bundled locale file wins as a whole. The default is `en_US`.

## Skills

| Skill | Task |
| --- | --- |
| [hashiiiii-git](skills/hashiiiii-git/SKILL.md) | Name branches and write commit messages |
| [hashiiiii-issues](skills/hashiiiii-issues/SKILL.md) | Create and edit GitHub issues |
| [hashiiiii-pull-request](skills/hashiiiii-pull-request/SKILL.md) | Create and edit pull requests |
| [hashiiiii-explain-pr](skills/hashiiiii-explain-pr/SKILL.md) | Explain a pull request from its diff and related code |
| [hashiiiii-locale](skills/hashiiiii-locale/SKILL.md) | Set language preferences |
| [hashiiiii-write-en](skills/hashiiiii-write-en/SKILL.md) | Write and review English; requires Node.js 20+ and npm 8.3+ |
| [hashiiiii-write-ja](skills/hashiiiii-write-ja/SKILL.md) | Write and review Japanese; requires Python 3 |
| [hashiiiii-zig](skills/hashiiiii-zig/SKILL.md) | Write and test Zig code |
| [hashiiiii-images](skills/hashiiiii-images/SKILL.md) | Create image assets; SVG conversion requires `rsvg-convert` |
| [hallmark](skills/hallmark/SKILL.md) | Design, audit, redesign, and study interfaces |
| [show-me](skills/show-me/SKILL.md) | Explain code and workflows visually |

[AGENTS.md](AGENTS.md) defines the shared rules, including required writing skills.  
See [maintenance](docs/MAINTENANCE.md) for checks, dependencies, and releases.

## License

[MIT](LICENSE.md). Bundled dependencies retain their own licenses.
