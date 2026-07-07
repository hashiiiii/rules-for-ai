---
name: hashiiiii-pull-request
description: Use when creating or editing a GitHub pull request. Structures PR bodies with Summary, Motivation, Changes, and Testing.
---

# Pull Request Conventions

Every pull request body uses the same headings in the same order.

## Locale

Before drafting a pull request:

1. Project instructions (`CLAUDE.md` / `AGENTS.md`) override resolved locale keys; follow them when they state a language for pull requests or issues
2. Otherwise use the resolved locale keys if they are already in context (plugin path)
3. Otherwise read `~/.config/rules-for-ai/LOCALE.md`
4. If missing, read the bundled `LOCALE.default.md`
5. Write the PR **title and body** in the language given by the `issues` key — pull requests share the issue prose locale

Section headings (Summary, Motivation, ...) are always English — the template structure never changes. When `issues` is `ja_JP`, keep the English headings and write the prose under each heading in Japanese.

## When to Use

- Before `gh pr create`
- Before editing a PR body (`gh pr edit --body`)
- When the user asks to draft a pull request

## Pull Request Body Template

Use exactly these headings in this order:

```markdown
## Summary

## Motivation

## Changes

## Testing
```

## Section Guide

| Section | Purpose |
|---------|---------|
| Summary | What this PR does, in one or two sentences |
| Motivation | Why the change is needed; link the issue with `Closes #NNN` |
| Changes | Notable changes, as a bullet list |
| Testing | Commands you ran and their result — real output, no mocks or stubs |

## Creating a Pull Request

Open as a draft while work is in progress:

```bash
gh pr create --draft --title "<type>: <subject>" --body "$(cat <<'EOF'
## Summary

## Motivation

## Changes

## Testing

EOF
)"
```

The `<type>: <subject>` title follows the same type vocabulary as the branch and commit (see the hashiiiii-git skill). If the repository ships a `.github/pull_request_template.md`, it mirrors these four sections.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Empty or vague Testing | Paste the actual commands and their output |
| Motivation folded into Summary | Summary is what changed; Motivation is why, with the issue link |
| Missing a heading | The PreToolUse hook blocks the create; all four headings are required |
| Reordering or renaming headings | Keep the four headings verbatim and in order |
