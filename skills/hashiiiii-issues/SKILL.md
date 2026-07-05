---
name: hashiiiii-issues
description: Use when creating or editing GitHub issues. Structures issue bodies with 背景, 問題, スコープ, 設計, Approve 条件, and その他.
---

# Issue Conventions

Every issue body uses the same headings in the same order.

## Locale

Before drafting an issue:

1. Read `./LOCALE.md` at the project root
2. If missing, read `rules-for-ai/LOCALE.default.md` (or `./LOCALE.default.md` when not using a submodule)
3. Write the issue **title and body** in the language given by the `Issues` row

Section headings (背景, 問題, ...) are always Japanese — the template structure never changes. When `Issues` is `en`, keep the Japanese headings and write the prose under each heading in English.

## When to Use

- Before `gh issue create`
- Before editing an issue body
- When the user asks to draft an issue

Not for PR descriptions, changelogs, or commit messages.

## Issue Body Template

Use exactly these headings in this order:

```markdown
## 背景

## 問題

## スコープ

### やること

### やらないこと

## 設計

## Approve 条件

## その他
```

## Section Guide

| Section | Purpose |
|---------|---------|
| 背景 | Why this work exists — context, motivation, prior decisions |
| 問題 | What is wrong or missing today — concrete symptoms or gaps |
| スコープ / やること | In-scope deliverables |
| スコープ / やらないこと | Explicit out-of-scope items |
| 設計 | Approach, alternatives considered, key decisions |
| Approve 条件 | Verifiable checklist for closing or approving the work |
| その他 | Links, dependencies, open questions, follow-ups |

`Approve 条件` uses `- [ ]` checkboxes. Each item must be objectively verifiable.

## Creating an Issue

```bash
gh issue create --title "<title>" --body "$(cat <<'EOF'
## 背景

## 問題

## スコープ

### やること

### やらないこと

## 設計

## Approve 条件

- [ ]

## その他

EOF
)"
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing やらないこと | Always list explicit out-of-scope items |
| Vague Approve 条件 | Use verifiable checkboxes |
| 設計 mixed into 問題 | Current state in 問題, solution in 設計 |
| Skipping 背景 | State why the work matters before the problem |
