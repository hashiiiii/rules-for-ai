# English Checker Runtime

The checker uses the pinned `harper.js` and `fflate` packages in `package.json` and `package-lock.json`.
It requires Node.js 20+ and npm 8.3+.

Run these commands with absolute paths:

```sh
node /path/to/hashiiiii-write-en/scripts/check.mjs setup
node /path/to/hashiiiii-write-en/scripts/check.mjs /path/to/draft.md
node /path/to/hashiiiii-write-en/scripts/check.mjs --dialect British /path/to/draft.md
```

Setup downloads locked packages without lifecycle scripts to `$XDG_CACHE_HOME/rules-for-ai/english/<lockfile-sha256>`, defaulting to `~/.cache/rules-for-ai/english/<lockfile-sha256>`.
A changed lockfile selects a new cache. Setup is safe to repeat and does not write to the project or skill directory.
Checks run offline; drafts stay on the machine.

The default dialect is American English. Other choices are British, Australian, Canadian, and Indian.
Markdown files use Harper's Markdown parser, which excludes code and link targets; other files use plain text.
The checker reports JSON diagnostics and suggestions without editing the input. Line and column numbers start at 1; columns count Unicode characters.
Exit status 0 means the check completed, even if suggestions remain. Status 1 means setup, input, or runtime failure.
Review suggestions in context and compare the draft with its source.

Harper uses the Apache-2.0 license; `fflate` uses MIT. npm retains both licenses in the cache.
