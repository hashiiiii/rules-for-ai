# Codex

This document explains the Codex installation and the locale process.

Install with [rules-for-ai.sh](../rules-for-ai.sh):

```bash
./rules-for-ai.sh install codex <user|project|local> [path/to/repo]
```

Restart Codex after installation. Codex reads its instructions when a session starts.

## Scopes

| Scope | Rules | Skills | Notes |
| --- | --- | --- | --- |
| **user** | `$CODEX_HOME/AGENTS.md` | `~/.agents/skills/` | `$CODEX_HOME` defaults to `~/.codex`. |
| **project** | `<repo>/AGENTS.md` | `<repo>/.agents/skills/` | Commit the installed files for your team. |
| **local** | `<repo>/AGENTS.md` | `<repo>/.agents/skills/` | Git excludes the installed files through `.git/info/exclude`. |

The installer keeps ownership copies of `AGENTS.md` and each installed skill.
When the active content matches its ownership copy, the installer can replace or remove the file.

If `AGENTS.md` already has other content, the installer does not change it.
It prints the source path so you can merge the rules manually.

The user support directory is `$CODEX_HOME/rules-for-ai/`.
The project and local support directory is `<repo>/.agents/rules-for-ai/`.
Each support directory contains the ownership copies and `LOCALE.default.md`.

## Native plugin

The repository also contains a Codex plugin manifest and marketplace file.
The plugin installs the skills and loads the shared hooks.
The `SessionStart` hook adds the rules and locale keys to the session context.
The `PreToolUse` hook checks pull request templates before the GitHub CLI runs matching commands.

Use these commands to install the native plugin:

```bash
codex plugin marketplace add hashiiiii/rules-for-ai
codex plugin add rules-for-ai@hashiiiii
```

When Codex requests approval, review and trust the plugin hooks.
Codex does not run untrusted plugin hooks.

If you want Codex to load rules through its native `AGENTS.md` process, use `rules-for-ai.sh`.
This method does not require plugin hook approval.

## Locale

Codex reads the locale process from the installed `AGENTS.md`.
It resolves the first existing locale file in this order:

1. `<absolute-git-dir>/rules-for-ai/LOCALE.md`
2. `<repo>/.rules-for-ai/LOCALE.md`
3. `~/.config/rules-for-ai/LOCALE.md`
4. The installed `LOCALE.default.md`
5. Inline `en_US` values

Codex reads repository instructions from the repository root to the current directory.
A nested `AGENTS.md` can add rules or override earlier rules.

## Removal

```bash
./rules-for-ai.sh uninstall codex <user|project|local> [path/to/repo]
```

The command removes only installer-owned files.
If the active `AGENTS.md` changed after installation, the command keeps it and prints a warning.

To remove only the native plugin, run:

```bash
codex plugin remove rules-for-ai@hashiiiii
```

See the official Codex guides for [AGENTS.md](https://developers.openai.com/codex/agent-configuration/agents-md), [skills](https://developers.openai.com/codex/build-skills), and [plugins](https://developers.openai.com/codex/plugins).
