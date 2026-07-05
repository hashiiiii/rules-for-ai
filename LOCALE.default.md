# Locale

Fallback language settings. Agents read this file when the project root has
no `LOCALE.md`.

To override, place a `LOCALE.md` at your project root — copy
`LOCALE.md.example` and edit it. `Language` accepts `ja` or `en` only. Rows
missing from `LOCALE.md` fall back to the values in this file.

| Artifact | Language |
|----------|----------|
| Issues | en |
| Code comments | en |
| Log messages | en |
| Test log messages | en |
