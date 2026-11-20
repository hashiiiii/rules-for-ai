---
name: hashiiiii-pull-request
description: Use this skill to create or edit a GitHub pull request with the repository template or the default structure.
---

# Pull Request Conventions

Use the repository's pull request template when one exists. Search in this order:

1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `pull_request_template.md`
4. A single Markdown file under `.github/PULL_REQUEST_TEMPLATE/`

If there are multiple templates, use the one selected by the user or repository. Preserve the selected template's headings, order, and subsections, and fill every heading.

Resolve the `pull-requests` language through the shared locale rules for the title and body. Preserve repository template headings. Keep default template headings in English.

For UI changes, attach before-and-after screenshots to the pull request body.

If no template exists, use:

```markdown
## Summary

## Motivation

## Changes

## Testing
```

| Section | Content |
| --- | --- |
| Summary | Describe the change in one or two sentences. |
| Motivation | Explain why and link a related issue with `Closes #NNN`. |
| Changes | List the important changes. |
| Testing | List commands run and their actual results. |

If work is incomplete, create a draft. Use the same type for the branch, commit, and title. See [hashiiiii-git](../hashiiiii-git/SKILL.md) for the type and title format.

Create a pull request with `gh pr create --title "<type>: <subject>" --body-file <file>`. Add `--draft` when work is incomplete.
