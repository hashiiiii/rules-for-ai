---
name: hashiiiii-issues
description: Use when creating or editing GitHub issues. Structures issue bodies with Background, Problem, Scope, Design, Acceptance criteria, and Notes.
---

# Issue Conventions

Every issue body uses the same headings in the same order.

## Locale

Before drafting an issue:

1. Use the resolved locale keys if they are already in context (plugin path)
2. Otherwise read `./LOCALE.md` at the project root
3. If missing, read `~/.config/rules-for-ai/LOCALE.md`
4. If missing, read the bundled `LOCALE.default.md`
5. Write the issue **title and body** in the language given by the `issues` key

Section headings (Background, Problem, ...) are always English — the template structure never changes. When `issues` is `ja_JP`, keep the English headings and write the prose under each heading in Japanese.

## When to Use

- Before `gh issue create`
- Before editing an issue body
- When the user asks to draft an issue

## Issue Body Template

Use exactly these headings in this order:

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
| Background | Why this work exists — context, motivation, prior decisions |
| Problem | What is wrong or missing today — concrete symptoms or gaps |
| Scope / In scope | In-scope deliverables |
| Scope / Out of scope | Explicit out-of-scope items |
| Design | Approach, alternatives considered, key decisions |
| Acceptance criteria | Verifiable checklist for closing or approving the work |
| Notes | Links, dependencies, open questions, follow-ups |

`Acceptance criteria` uses `- [ ]` checkboxes. Each item must be objectively verifiable.

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
| Missing Out of scope | Always list explicit out-of-scope items |
| Vague Acceptance criteria | Use verifiable checkboxes |
| Design mixed into Problem | Current state in Problem, solution in Design |
| Skipping Background | State why the work matters before the problem |
