---
name: hashiiiii-issues
description: Use this skill to create or edit GitHub issues with a consistent body structure.
---

# Issue Conventions

Use the same headings and order in every issue body.

## Locale

Before you draft an issue, resolve its language:

1. If project instructions specify an issue language, use that language.
2. If project instructions do not specify a language, use the resolved `issues` key from the context.
3. If the context has no resolved keys, read the first existing locale file.
4. Use this file order: local, project, user, and bundled `LOCALE.default.md`.
5. Use `<absolute-git-dir>/rules-for-ai/LOCALE.md` for the local file.
6. Use `<repo>/.rules-for-ai/LOCALE.md` for the project file.
7. Use `${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md` for the user file.
8. If no locale file exists, use `en_US`.
9. Use the `issues` language for the issue title and body.

Always write the section headings in English. Do not change the template structure.

If `issues` is `ja_JP`, keep the English headings. Write the text below each heading in Japanese.

## When to Use

- Before `gh issue create`
- Before you edit an issue body
- If the user asks you to draft an issue

## Issue Body Template

Use these exact headings in this order:

```markdown
## Background

## Problem

## Scope

### In scope

### Out of scope

## Design

## Acceptance criteria

## Notes
```

## Section Guide

| Section | Purpose |
|---------|---------|
| Background | Explain the context, reason, and earlier decisions. |
| Problem | Describe current defects or missing behavior. |
| Scope / In scope | List the required deliverables. |
| Scope / Out of scope | List the excluded items. |
| Design | Describe the method, alternatives, and important decisions. |
| Acceptance criteria | Give an objective checklist for approval or closure. |
| Notes | Add links, dependencies, open questions, and later work. |

Use `- [ ]` checkboxes in `Acceptance criteria`. Each item must have an objective result.

## Creating an Issue

```bash
gh issue create --title "<title>" --body "$(cat <<'EOF'
## Background

## Problem

## Scope

### In scope

### Out of scope

## Design

## Acceptance criteria

- [ ]

## Notes

EOF
)"
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing Out of scope | Always list the excluded items. |
| Vague Acceptance criteria | Use checkboxes with objective results. |
| Design information in Problem | Put the current state in Problem. Put the solution in Design. |
| Missing Background | Explain the reason for the work before the problem. |
