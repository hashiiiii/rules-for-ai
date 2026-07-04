---
name: git-conventions
description: Use when creating a git branch or writing a git commit message in any project — at the moment you run `git switch -c` / `git checkout -b` or `git commit`. Symptoms: unsure what to name a branch, which type/prefix to use, how long a commit subject may be, or whether to add a commit body.
---

# Git Conventions

## Overview

One shared `type` vocabulary drives two artifacts: the **branch name** and the **commit subject**. Decide the type once and both line up.

## When to Use

- Right before `git switch -c` / `git checkout -b` — naming a branch
- Right before `git commit` — writing the message

Not for: choosing a branching strategy (git-flow vs trunk), squash/rebase policy, or release tagging.

## The Contract — what each artifact IS

**Branch** — `<type>/<short-english-kebab>`
- English, kebab-case, terse. No issue numbers, no extra prefixes, no personal names, no Japanese.
- e.g. `feat/yaml-parser`, `fix/nested-override-diff`, `docs/cli-usage`

**Commit** — a single line: `<type>: <subject>`
- The subject is **English**, imperative mood, lowercase first word, no trailing period, **≤ 50 characters**.
- The message is **exactly one line**. The subject line is the whole message — nothing follows it.
- e.g. `feat: add YAML parser for .prefab files`

## Type vocabulary (shared by branch and commit)

| type | use when |
|------|----------|
| `feat` | a new feature or capability |
| `fix` | a bug fix |
| `docs` | documentation only |
| `style` | formatting / whitespace, no behavior change |
| `refactor` | restructuring without behavior change |
| `perf` | performance improvement |
| `test` | adding or fixing tests |
| `build` | build system or dependencies |
| `ci` | CI configuration |
| `chore` | misc maintenance (e.g. `.gitignore`) |
| `revert` | reverting a prior commit |

Pick the closest one. Do not invent new types.

## Worked example

Change: implemented a YAML parser for `.prefab` files.

```bash
# 1. branch — type / english-kebab
git switch -c feat/yaml-parser

# 2. commit — one line, English subject ≤ 50 chars, imperative, no body
git commit -m "feat: add YAML parser for .prefab files"
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Adding a body / bullet points under the subject | The commit is one line. Keep extra detail out of the commit message. |
| Writing the subject in Japanese | The whole message is English — imperative, lowercase first word. |
| Subject longer than 50 characters | Trim to the essence. 50 chars is the hard limit. |
| Branch like `feature/…`, `bugfix/…`, `john/…`, or with Japanese | Use a `type` from the table + a short english kebab description. |
| Inventing a new type | Only the 11 types above exist. Pick the closest. |
