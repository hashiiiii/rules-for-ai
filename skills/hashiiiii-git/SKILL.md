---
name: hashiiiii-git
description: Use this skill to name a Git branch or write a commit message.
---

# Git Conventions

Use the same `type` for the **branch name** and the **commit subject**. Select the type one time.

## When to Use

- Before `git switch -c` or `git checkout -b`
- Before `git commit`

This skill does not define branch strategy, squash policy, rebase policy, or release tags.

## Branch

`<type>/<short-english-kebab>`

Use short English words in kebab-case. Do not use issue numbers, additional prefixes, personal names, or Japanese text.

Examples: `feat/yaml-parser`, `fix/nested-override-diff`, `docs/cli-usage`

## Commit

Use this format on one line: `<type>: <subject>`

Write the subject in English and use the imperative form. Start with a lowercase word.

Do not add a final period. Use 50 characters or fewer.

Example: `feat: add YAML parser for .prefab files`

## Types

| Type | Use |
|------|----------|
| `feat` | Add a feature or capability. |
| `fix` | Correct a defect. |
| `docs` | Change documentation only. |
| `style` | Change formatting or whitespace without behavior changes. |
| `refactor` | Change code structure without behavior changes. |
| `perf` | Improve performance. |
| `test` | Add or correct tests. |
| `build` | Change the build system or dependencies. |
| `ci` | Change the CI files. |
| `chore` | Do maintenance, such as a `.gitignore` change. |
| `revert` | Revert an earlier commit. |

Select the closest type. Do not create a new type.

## Example

```bash
git switch -c feat/yaml-parser
git commit -m "feat: add YAML parser for .prefab files"
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Body or bullets below the subject | Use one line only. |
| Japanese subject | Use English and the imperative form. Start with a lowercase word. |
| Subject with more than 50 characters | Use 50 characters or fewer. |
| Branch such as `feature/…`, `bugfix/…`, `john/…`, or Japanese text | Use `<type>/<english-kebab>` with a type from the table. |
| New type | Use one of the 11 types in the table. |
