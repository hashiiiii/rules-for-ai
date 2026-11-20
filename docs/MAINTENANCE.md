# Maintenance

## Checks

These checks use Git, jq, Python 3, Node.js 20 or later, and npm 8.3 or later.

```sh
sh -c 'for f in tests/*.test.sh; do sh "$f" || exit 1; done'
sh scripts/sync-upstreams.sh --check
sh scripts/check-versions.sh
```

CI also runs ShellCheck, checks that `rules/agents.mdc` matches `AGENTS.md`, and tests both Claude Code and Codex plugins.  
Edit `AGENTS.md` and synchronize `rules/agents.mdc`; `CLAUDE.md` is a symlink to `AGENTS.md`.

## Dependencies

Renovate updates GitHub Actions, the Codex and Claude Code versions in the CI workflow, and the `bump-my-version` version in the release workflow.
It also updates bundled sources in `upstreams.json` and the English checker's npm manifests.

Updates require a release timestamp and seven days of release age. Automatic merging is disabled.  
The **dependency updates** workflow runs on Mondays at 06:00 JST or through its manual trigger.

`upstreams.json` records source commits, copied paths, and ordered patches.  
Edit public skill wrappers directly. For bundled changes, edit the manifest or patches under `patches/<name>/`, then regenerate:

```sh
sh scripts/sync-upstreams.sh
sh scripts/sync-upstreams.sh --check
```

These commands require Git, jq, and network access. Do not edit generated files under `skills/*/vendor/`.  
For tagged sources, update the version and commit together; for tracked refs, update the commit.  
Resolve patch conflicts and regenerate before merging an update.

For English checker updates, regenerate its npm lockfile and run `sh tests/english-writing.test.sh`.  
See its [runtime documentation](../skills/hashiiiii-write-en/DEPENDENCIES.md) for setup and cache paths.

## Releases

Run **Actions → release → Run workflow** on `main`. Enter `X.Y.Z` without a `v` prefix.  
The workflow updates the plugin versions, commits, tags, and creates a GitHub release. Do not create local release tags.

Both maintenance workflows require the GitHub App secrets `APP_CLIENT_ID` and `APP_PRIVATE_KEY`.  
The App needs Contents, Pull requests, and Workflows write permissions and must be a bypass actor for the `main` ruleset so it can push release commits.
