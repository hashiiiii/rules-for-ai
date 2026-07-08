---
name: hashiiiii-pull-request
description: Use when creating or editing a GitHub pull request. Follow the repository PR template when one exists; otherwise use the default Summary / Motivation / Changes / Testing structure.
---

# Pull Request Conventions

The pull request body structure comes from the repository. Do not impose a fixed format when the repo already defines one.

## Locale

Before drafting a pull request:

1. Project instructions (`CLAUDE.md` / `AGENTS.md`) override resolved locale keys; follow them when they state a language for pull requests
2. Otherwise use the resolved locale keys if they are already in context (plugin path)
3. Otherwise read `~/.config/rules-for-ai/LOCALE.md`
4. If missing, read the bundled `LOCALE.default.md`
5. Write the PR **title and body** in the language given by the `pull-requests` key

Use section headings exactly as they appear in the template you follow. When using the default fallback below, headings stay English — only the prose changes with locale. When `pull-requests` is `ja_JP`, keep those English headings and write the prose under each heading in Japanese.

## When to Use

- Before `gh pr create`
- Before editing a PR body (`gh pr edit --body`)
- When the user asks to draft a pull request

## Repository Template (preferred)

Before drafting, look for a pull request template in the target repository:

1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `pull_request_template.md` at the repository root
4. A single `.md` file under `.github/PULL_REQUEST_TEMPLATE/`

When one exists, read it and follow its headings, order, and subsections verbatim. Fill in every `##` section the template defines. If the repository has multiple templates under `.github/PULL_REQUEST_TEMPLATE/`, follow whichever template the user or repository conventions point to.

## Default Template (fallback)

Use this structure only when the repository has no pull request template:

```markdown
## Summary

## Motivation

## Changes

## Testing
```

### Default Section Guide

| Section | Purpose |
|---------|---------|
| Summary | What this PR does, in one or two sentences |
| Motivation | Why the change is needed; link the issue with `Closes #NNN` |
| Changes | Notable changes, as a bullet list |
| Testing | Commands you ran and their result — real output, no mocks or stubs |

## Creating a Pull Request

Open as a draft while work is in progress.

When the repository has a template, base the body on that file. When it does not, use the default fallback:

```bash
gh pr create --draft --title "<type>: <subject>" --body "$(cat <<'EOF'
## Summary

## Motivation

## Changes

## Testing

EOF
)"
```

The `<type>: <subject>` title follows the same type vocabulary as the branch and commit (see the hashiiiii-git skill).

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Ignoring the repo template | Read the repository template first; only use the default fallback when none exists |
| Empty or vague Testing | Paste the actual commands and their output |
| Motivation folded into Summary | Summary is what changed; Motivation is why, with the issue link |
| Missing a template section | Include every `##` heading from the template you are following |
| Reordering or renaming headings | Keep the template's headings verbatim and in order |
