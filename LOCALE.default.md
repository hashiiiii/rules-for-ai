# Locale

Fallback language settings. Agents read this file only when no user-level `LOCALE.md` exists — the first existing file wins as a whole; layers never merge.

To override, run the hashiiiii-locale skill or create `~/.config/rules-for-ai/LOCALE.md` manually, keeping all four keys.

POSIX-style locale tags (e.g. `ja_JP`, `en_US`, `en_GB`).

issues=en_US
comments=en_US
logs=en_US
test-logs=en_US
