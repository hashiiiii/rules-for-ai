# Locale

Fallback language settings. Agents read this file when the project root has no `LOCALE.md`.

To override, place a `LOCALE.md` at your project root — copy `LOCALE.md.example` and edit it.
`Language` uses BCP 47 locale tags (e.g. `ja_JP`, `en_US`, `en_GB`).
Rows missing from `LOCALE.md` fall back to the values in this file.

| Artifact | Language |
|----------|----------|
| Issues | en_US |
| Code comments | en_US |
| Log messages | en_US |
| Test log messages | en_US |
