---
name: hashiiiii-issues
description: Use this skill to create or edit GitHub issues with a consistent body structure.
---

# Issue Conventions

Resolve the `issues` language through the shared locale rules for the title and body. Keep headings in English and use this structure in this order:

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

Use **Background** for the context, reason, and earlier decisions. Describe current defects or missing behavior in **Problem**. List deliverables and exclusions under **In scope** and **Out of scope**; explain the approach and key decisions under **Design**; and put links, dependencies, or open questions in **Notes**. Make **Acceptance criteria** objective `- [ ]` items.

Create an issue with `gh issue create --title "<title>" --body-file <file>`.
