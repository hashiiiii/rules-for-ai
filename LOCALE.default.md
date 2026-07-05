# Locale

Fallback language settings. Agents read this file only when no project-root `LOCALE.md` and no user-level `LOCALE.md` exists — the first existing file wins as a whole; layers never merge.

To override, place a `LOCALE.md` at your project root — copy `LOCALE.md.example` and edit it, keeping all four keys.

POSIX-style locale tags (e.g. `ja_JP`, `en_US`, `en_GB`).

issues=en_US
comments=en_US
logs=en_US
test-logs=en_US
