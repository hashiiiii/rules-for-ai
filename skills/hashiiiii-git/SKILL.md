---
name: hashiiiii-git
description: Use when naming a git branch or writing a commit message.
---

# Git Conventions

One `type` vocabulary for both the **branch name** and **commit subject**. Pick the type once.

## When to Use

- Before `git switch -c` / `git checkout -b`
- Before `git commit`

Not for branching strategy, squash/rebase policy, or release tagging.

## Branch

`<type>/<short-english-kebab>`

English, kebab-case, terse. No issue numbers, extra prefixes, personal names, or Japanese.

Examples: `feat/yaml-parser`, `fix/nested-override-diff`, `docs/cli-usage`

## Commit

`<type>: <subject>` — one line only, no body.

English, imperative, lowercase first word, no trailing period, ≤ 50 characters.

Example: `feat: add YAML parser for .prefab files`

## Types

| type | use when |
|------|----------|
| `feat` | new feature or capability |
| `fix` | bug fix |
| `docs` | documentation only |
| `style` | formatting / whitespace, no behavior change |
| `refactor` | restructuring without behavior change |
| `perf` | performance improvement |
| `test` | adding or fixing tests |
| `build` | build system or dependencies |
| `ci` | CI configuration |
| `chore` | misc maintenance (e.g. `.gitignore`) |
| `revert` | reverting a prior commit |

Pick the closest type. Do not invent new ones.

## Example

```bash
git switch -c feat/yaml-parser
git commit -m "feat: add YAML parser for .prefab files"
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Body or bullets under the subject | One line only |
| Japanese subject | English, imperative, lowercase first word |
| Subject > 50 characters | Trim to ≤ 50 |
| Branch like `feature/…`, `bugfix/…`, `john/…`, or Japanese | `<type>/<english-kebab>` from the table |
| New type | Use one of the 11 types above |
