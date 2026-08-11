---
name: hashiiiii-pull-request
description: Use this skill to create or edit a GitHub pull request with the repository template or the default structure.
---

# Pull Request Conventions

Use the pull request structure from the repository. If the repository defines a structure, do not replace it.

## Locale

Before you draft a pull request, resolve its language:

1. If project instructions specify a pull request language, use that language.
2. If project instructions do not specify a language, use the resolved `pull-requests` key from the context.
3. If the context has no resolved keys, read the first existing locale file.
4. Use this file order: local, project, user, and bundled `LOCALE.default.md`.
5. Use `<absolute-git-dir>/rules-for-ai/LOCALE.md` for the local file.
6. Use `<repo>/.rules-for-ai/LOCALE.md` for the project file.
7. Use `${XDG_CONFIG_HOME:-${HOME:-}/.config}/rules-for-ai/LOCALE.md` for the user file.
8. If no locale file exists, use `en_US`.
9. Use the `pull-requests` language for the pull request title and body.

Use the exact section headings from the selected template. For the default structure, always write the headings in English.

If `pull-requests` is `ja_JP`, keep the English headings. Write the text below each heading in Japanese.

## When to Use

- Before `gh pr create`
- Before you edit a pull request body with `gh pr edit --body`
- If the user asks you to draft a pull request

## Repository Template (preferred)

Before you draft the body, search for a pull request template in this order:

1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `pull_request_template.md` at the repository root
4. A single `.md` file under `.github/PULL_REQUEST_TEMPLATE/`

If a template exists, read it. Use its headings, order, and subsections without changes.

Fill every Markdown ATX heading that the template defines (`#` through `######`).

If the repository has multiple templates, use the template that the user or repository selects.

## Default Template (fallback)

If the repository has no pull request template, use this structure:

```markdown
## Summary

## Motivation

## Changes

## Testing
```

### Default Section Guide

| Section | Purpose |
|---------|---------|
| Summary | Describe the pull request in one or two sentences. |
| Motivation | Explain the reason for the change. Link the issue with `Closes #NNN`. |
| Changes | List important changes. |
| Testing | List the commands that you ran and their results. Use real output without mocks or stubs. |

## Creating a Pull Request

If the work is not complete, open the pull request as a draft.

If the repository has a template, use that file. If it has no template, use this default structure:

```bash
gh pr create --draft --title "<type>: <subject>" --body "$(cat <<'EOF'
## Summary

## Motivation

## Changes

## Testing

EOF
)"
```

Use the same type for the `<type>: <subject>` title, branch, and commit. See the `hashiiiii-git` skill.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Ignore the repository template | Read the repository template first. If no template exists, use the default structure. |
| Empty or vague Testing | Add the actual commands and their output. |
| Put Motivation information in Summary | Put the change in Summary. Put its reason and issue link in Motivation. |
| Omit a template section | Include every Markdown ATX heading from the selected template. |
| Change the heading order or names | Keep the exact headings and order from the template. |
