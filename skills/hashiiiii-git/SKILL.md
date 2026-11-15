---
name: hashiiiii-git
description: Use this skill to name a Git branch or write a commit message.
---

# Git Conventions

Use the same type for the branch name and commit subject.

## Branch

Format: `<type>/<short-english-kebab>`

Use short English words. Exclude issue numbers, extra prefixes, personal names, and Japanese text from the branch name.

## Commit

Format: `<type>: <subject>`

Write one imperative English line of 50 characters or fewer. Start the subject with a lowercase word and omit the final period.

## Types

| Type | Use |
| --- | --- |
| `feat` | Add a feature or capability. |
| `fix` | Correct a defect. |
| `docs` | Change documentation only. |
| `style` | Change formatting or whitespace without changing behavior. |
| `refactor` | Restructure code without changing behavior. |
| `perf` | Improve performance. |
| `test` | Add or correct tests. |
| `build` | Change the build system or dependencies. |
| `ci` | Change CI files. |
| `chore` | Do maintenance, such as a `.gitignore` change. |
| `revert` | Revert an earlier commit. |

Choose the closest type from this list.
