# English checker dependencies

[Harper](https://github.com/Automattic/harper) checks English grammar, spelling, and word usage locally.
This skill uses its official `harper.js` package and the full inlined WebAssembly engine.
The exact package versions and integrity hashes are in `package.json` and `package-lock.json` beside this file.
Harper is Apache-2.0; its `fflate` dependency is MIT. npm retains their licenses in the installed cache.

Run these commands with absolute paths from any working directory:

```sh
node /path/to/hashiiiii-write-en/scripts/check.mjs setup
node /path/to/hashiiiii-write-en/scripts/check.mjs /path/to/draft.md
node /path/to/hashiiiii-write-en/scripts/check.mjs --dialect British /path/to/draft.md
```

Setup requires Node.js 20 or later, npm 8.3 or later, and network access to the package registry.
It runs `npm ci --ignore-scripts --no-audit --no-fund` in a temporary cache directory and publishes it after installation succeeds.
It does not write to the project or plugin resources.
The cache is `$XDG_CACHE_HOME/rules-for-ai/english/<lockfile-sha256>`, or `~/.cache/rules-for-ai/english/<lockfile-sha256>` when unset.
A changed lockfile selects a separate cache. Setup is safe to repeat.

Checks use the installed JavaScript and inlined WebAssembly without fetching a remote binary or sending the draft anywhere.
They report JSON containing the engine version, dialect, file path, content SHA-256, and diagnostics with suggested replacements.
Line and column numbers are one-based; columns count Unicode characters.
Markdown code and link targets are excluded by Harper's parser.
Exit status 0 means checking completed, including when suggestions remain. Status 1 means setup, input, or runtime failure.
The checker does not edit the input.

## Maintenance

Renovate's npm manager updates both manifests under the repository's seven-day release-age policy.
The `fflate` override gives this transitive dependency its own version pin and Renovate update path under the same policy.
For a manual update, change the dependency and regenerate the lockfile with npm, then run `sh tests/english-writing.test.sh`.
The integration test uses the real engine and installed skill copies to catch incompatible package APIs.
The JavaScript API is still described as early access upstream; exact pins and these tests make updates reviewable.

## Selection

The replacement uses Harper 3.0.0, published on October 27, 2026. The newer 3.2.0 was too recent for the seven-day policy on November 15.
Harper's core provides grammar and spelling checks; editorial judgment and factual comparison remain the agent's responsibility.

| Candidate | Fit and limitation |
| --- | --- |
| [Humanizer](https://github.com/blader/humanizer) | Instructions for removing formulaic prose; no mechanical grammar checker. |
| [Vale](https://vale.sh/) | Established local style linter; its separately maintained Harper port omits spelling and implements a subset of an older engine. |
| [proselint](https://github.com/amperser/proselint) | Established prose-style checks, rather than general grammar checking. |
| [write-good](https://github.com/btford/write-good) | Readability suggestions such as wordiness and passive voice; narrower than grammar checking. |
| [Harper](https://writewithharper.com/docs/harperjs/node) | Full local grammar engine through npm and WebAssembly; avoids platform-specific binary installation. |

The npm package is about 95 MB unpacked. It is downloaded once per lockfile and shared by installed copies of this skill.
No linter can establish that prose is natural or factually correct; review the whole draft and compare it with the source.
